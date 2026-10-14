using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Win32.SafeHandles;

namespace CloudreachOwnedImage {
    // Acquire before Process.Start, keep until exact owned child is confirmed
    // exited. The hashed executable is held read-only, denying write/delete.
    public sealed class ExecutableLease : IDisposable {
        readonly FileStream stream;
        public string Path { get; }
        public string Sha256 { get; }
        public bool Active => stream.CanRead;
        public ExecutableLease(string path, string expectedHash) {
            if (!System.IO.Path.IsPathFullyQualified(path)) throw new ArgumentException("absolute_image_required");
            Path = System.IO.Path.GetFullPath(path);
            for (string p = Path; !string.IsNullOrEmpty(p); p = System.IO.Path.GetDirectoryName(p))
                if ((File.GetAttributes(p) & FileAttributes.ReparsePoint) != 0) throw new IOException("image_reparse_path");
            stream = new FileStream(Path, FileMode.Open, FileAccess.Read, FileShare.Read);
            try {
                Sha256 = Convert.ToHexString(SHA256.HashData(stream)).ToLowerInvariant();
                if (!String.Equals(Sha256, expectedHash, StringComparison.Ordinal)) throw new IOException("image_hash_mismatch");
            } catch { stream.Dispose(); throw; }
        }
        public void Dispose() => stream.Dispose();
    }

    public sealed class NativeObservation {
        public uint Pid { get; set; }
        public int PidError { get; set; }
        public uint BeforeWait { get; set; }
        public int BeforeWaitError { get; set; }
        public bool QueryOk { get; set; }
        public int QueryError { get; set; }
        public uint Chars { get; set; }
        public string Path { get; set; }
        public uint AfterWait { get; set; }
        public int AfterWaitError { get; set; }
    }
    public sealed class Proof {
        public bool Passed { get; set; }
        public string Failure { get; set; }
        public string Api { get; set; } = "QueryFullProcessImageNameW";
        public string HandleBinding { get; set; } = "constructor_supplied_owned_SafeProcessHandle";
        public int ExpectedPid { get; set; }
        public string ExpectedPath { get; set; }
        public string ExpectedSha256 { get; set; }
        public string LockedFileSha256 { get; set; }
        public bool FileLeaseActive { get; set; }
        public int BufferCapacity { get; set; } = ImageVerifier.Capacity;
        public int QueryBudgetMs { get; set; }
        public double ElapsedMs { get; set; }
        public NativeObservation Actual { get; set; }
    }
    public sealed class ImageVerifier : IDisposable {
        public const int Capacity = 32768;
        public const int MaxBudgetMs = 1000;
        const uint WaitTimeout = 258;
        readonly SafeProcessHandle handle;
        readonly int expectedPid;
        readonly ExecutableLease lease;
        bool held;
        int disposed;
        int failed;
        int active;
        [DllImport("kernel32.dll", SetLastError=true)]
        static extern uint GetProcessId(SafeProcessHandle process);
        [DllImport("kernel32.dll", SetLastError=true)]
        static extern uint WaitForSingleObject(SafeProcessHandle process, uint milliseconds);
        [DllImport("kernel32.dll", CharSet=CharSet.Unicode, ExactSpelling=true, SetLastError=true)]
        static extern bool QueryFullProcessImageNameW(SafeProcessHandle process, uint flags, StringBuilder buffer, ref uint chars);

        public ImageVerifier(SafeProcessHandle ownedHandle, int pid, ExecutableLease image) {
            if (ownedHandle == null || ownedHandle.IsClosed || ownedHandle.IsInvalid || pid <= 0 || image == null || !image.Active)
                throw new ArgumentException("invalid_owned_handle_or_lease");
            handle = ownedHandle; expectedPid = pid; lease = image;
            handle.DangerousAddRef(ref held);
        }
        public Proof Query(int budgetMs) => Run(budgetMs, Capture);
        Proof BaseProof(int budgetMs) => new Proof {
            ExpectedPid=expectedPid, ExpectedPath=lease.Path, ExpectedSha256=lease.Sha256,
            LockedFileSha256=lease.Sha256, FileLeaseActive=lease.Active, QueryBudgetMs=budgetMs
        };
        Proof Fail(Proof p, string reason) { p.Failure=reason; p.Passed=false; Interlocked.Exchange(ref failed,1); return p; }

        // A timeout permanently faults this verifier. No fallback, second query
        // or worker accumulation is allowed. Timeout does NOT cancel the Win32
        // call; the worker holds its own handle reference until it returns.
        internal Proof Run(int budgetMs, Func<SafeProcessHandle,NativeObservation> capture) {
            var p = BaseProof(budgetMs);
            if (budgetMs < 1 || budgetMs > MaxBudgetMs) return Fail(p,"invalid_query_budget");
            if (Volatile.Read(ref disposed)!=0 || handle.IsClosed || handle.IsInvalid) return Fail(p,"closed_owned_handle");
            if (Volatile.Read(ref failed)!=0) return Fail(p,"previous_failure_no_retry");
            if (!lease.Active) return Fail(p,"image_lease_closed");
            if (Interlocked.CompareExchange(ref active,1,0)!=0) return Fail(p,"query_already_in_flight");
            var timer=Stopwatch.StartNew(); bool workerRef=false;
            try {
                handle.DangerousAddRef(ref workerRef);
                var task=Task.Run(() => {
                    try { return capture(handle); }
                    finally { handle.DangerousRelease(); Interlocked.Exchange(ref active,0); }
                });
                workerRef=false; // ownership transferred to worker finally
                if (!task.Wait(budgetMs)) { p.ElapsedMs=timer.Elapsed.TotalMilliseconds; return Fail(p,"query_deadline"); }
                p.ElapsedMs=timer.Elapsed.TotalMilliseconds;
                p.Actual=task.GetAwaiter().GetResult(); // completed task only
                p.FileLeaseActive=lease.Active;
                if (p.ElapsedMs > budgetMs) return Fail(p,"query_deadline");
                string error=Validate(p.Actual,expectedPid,lease.Path,lease.Active);
                if (error!=null) return Fail(p,error);
                p.Passed=true;return p;
            } catch(Exception e) { p.ElapsedMs=timer.Elapsed.TotalMilliseconds;return Fail(p,"query_exception:"+e.GetType().Name); }
            finally { if(workerRef) { handle.DangerousRelease(); Interlocked.Exchange(ref active,0); } }
        }
        static NativeObservation Capture(SafeProcessHandle owned) {
            var n=new NativeObservation();
            n.Pid=GetProcessId(owned);n.PidError=n.Pid==0?Marshal.GetLastWin32Error():0;
            n.BeforeWait=WaitForSingleObject(owned,0);n.BeforeWaitError=n.BeforeWait==uint.MaxValue?Marshal.GetLastWin32Error():0;
            // Do not query an invalid, exited, or unsynchronizable process.
            if(n.Pid==0 || n.BeforeWait!=WaitTimeout) return n;
            var buffer=new StringBuilder(Capacity);uint chars=Capacity;
            n.QueryOk=QueryFullProcessImageNameW(owned,0,buffer,ref chars);
            n.QueryError=n.QueryOk?0:Marshal.GetLastWin32Error();
            n.Chars=chars;n.Path=buffer.ToString();
            n.AfterWait=WaitForSingleObject(owned,0);n.AfterWaitError=n.AfterWait==uint.MaxValue?Marshal.GetLastWin32Error():0;
            return n;
        }
        internal static string Validate(NativeObservation n,int pid,string path,bool leaseActive) {
            if(n==null)return "missing_native_observation";
            if(n.Pid==0)return "handle_pid_query_failed";
            if(n.Pid!=pid)return "owned_handle_pid_mismatch";
            if(n.BeforeWait!=WaitTimeout)return "process_not_live_before_query";
            if(!n.QueryOk)return "image_query_failed:"+n.QueryError;
            if(n.Chars==0 || n.Chars>=Capacity || n.Path==null || n.Path.Length!=n.Chars || n.Path.IndexOf('\0')>=0)return "invalid_image_length";
            if(!String.Equals(n.Path,path,StringComparison.OrdinalIgnoreCase))return "image_path_mismatch";
            if(n.AfterWait!=WaitTimeout)return "process_not_live_after_query";
            if(!leaseActive)return "image_lease_closed";
            return null;
        }
        public void Dispose() {
            if(Interlocked.Exchange(ref disposed,1)==0 && held){handle.DangerousRelease();held=false;}
        }
    }
}
