Independent source/correctness review: bounded PASS; engine checks/performance pending.

Reviewer /root/c3_journal_review compared candidate29237b38efd3c011b88a5588e92e319b05b90c98 with e2fa5e4e6bb0060e5f98f9129f2f2e949f8a37f3. Exactly7changedfiles verified:3game scripts,2-keyperformanceconfigdelta,reusedexistingDBtest,2evidencefiles. Game scripts/test Gitblob-identical to existing dependency863e20cce, which merges mainbase. No culling/batching/geometry/physics/sharedsave/RPC/F32_source_service change.

Harvest731-744 throttles idle stock reads and bypasses timer on Game.day change;811-826 refreshes before readiness/expectedrevision capture. Request remains site identity, stockrevision and actionID. Taken/claiming guards, delta/settled listeners, stockCAS, owner-save/ACK, inventory publication and feedback unchanged. F32 runtime flag still reads per stockquery, avoiding the omitted mtime-only stalecache.

Move/TM publicrecords deepcopied; compatibletypes copied; scalarqueries onlyreadinternal tables. Reviewedcallers do notmutateinternals. Explicit newDB instances retain independentconstruction.

Qualifications: mtime+size is not universalinvalidation; equal-size rewriteswithinone timestampsecond canretainoldtables. No gameplaywriter/existingtestdependencefound; immutable shippingPCKdata fits narrowproof. Existingcomments overstate reload guarantees. Firststockread happens oneachnodebefore nextpoll randomization; noinitialspikeavoidanceclaim.

Existingproofscope: sharedDBtest verifiesidentity/mutationisolation, notinvalidation; F19smoke verifies detached/mountedpresentation, nottimercadence/day/pre-submitbranches; foundationsave test verifies actualregistry/diskwriters/rollback/retry withdisclosedfixtures, noENet; nodecontentionsmoke is actualtwo-peerrequest/CAS/ACK, nofour-peer/fullcampaignclaim. SourcePASS establishesneitherGodotruntimePASSnorFPSrecovery.
