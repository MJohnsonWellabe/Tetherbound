using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading;
using Microsoft.Win32.SafeHandles;

// Owns a reference to the exact handle obtained from Process.Start, never a PID
// lookup. The timer caps the child even if supervisor telemetry blocks.
public sealed class CloudreachHandleDeadline : IDisposable {
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern bool TerminateProcess(SafeProcessHandle handle, uint exitCode);
    readonly SafeProcessHandle handle;
    readonly Timer timer;
    readonly int ownedPid;
    CloudreachOwnedImage.ImageVerifier imageVerifier;
    bool held;
    int expired;
    int attempted;
    public bool Expired => Volatile.Read(ref expired) != 0;
    public bool TerminationAttempted => Volatile.Read(ref attempted) != 0;
    public CloudreachHandleDeadline(Process process, int remainingMs) {
        if (remainingMs <= 0 || remainingMs > 60000) throw new ArgumentOutOfRangeException();
        handle = process.SafeHandle;
        ownedPid = process.Id;
        handle.DangerousAddRef(ref held);
        timer = new Timer(_ => {
            Interlocked.Exchange(ref expired, 1);
            Interlocked.Exchange(ref attempted, 1);
            TerminateProcess(handle, 124);
        }, null, remainingMs, Timeout.Infinite);
    }
    // Review candidate only: bind a prelaunch hash-locked executable lease.
    public void BindImageLease(CloudreachOwnedImage.ExecutableLease lease) {
        if (imageVerifier != null) throw new InvalidOperationException("image verifier already bound");
        imageVerifier = new CloudreachOwnedImage.ImageVerifier(handle, ownedPid, lease);
    }
    public CloudreachOwnedImage.Proof QueryOwnedImage(int remainingWallMs) {
        if (imageVerifier == null) throw new InvalidOperationException("image verifier unbound");
        return imageVerifier.Query(Math.Min(1000, remainingWallMs));
    }
    public bool RequestOwnedStop() => TerminateProcess(handle, 124);
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern uint WaitForSingleObject(SafeProcessHandle process, uint milliseconds);
    public bool WaitOwnedExit(int timeoutMs) {
        if (timeoutMs < 0 || timeoutMs > 5000) throw new ArgumentOutOfRangeException();
        uint result = WaitForSingleObject(handle, (uint)timeoutMs);
        if (result == uint.MaxValue) throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
        return result == 0;
    }
    public void Dispose() {
        // Wait only for this short native-handle callback, no script/IO callbacks.
        using (var done = new ManualResetEvent(false)) {
            if (!timer.Dispose(done) || !done.WaitOne(1000)) return;
        }
        if (imageVerifier != null) imageVerifier.Dispose();
        if (held) { handle.DangerousRelease(); held = false; }
    }
}
