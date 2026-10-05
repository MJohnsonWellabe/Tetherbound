Main33431f9a Meadows Medium, background trace unset

Native exit0/no ERROR; 497.562s including production boot. GTX1060 3GB, Forward+,1920x1080,uncapped/VSync0,normal60Hz/time1,livefar2000m. Main334 has no blocked detail_cull. Same diagnostic host/PCK and existing overlay as the trace-enabled case; not shipping EXE or Ally FPS.

191 wall frames/191 correlated EngineProfiler iterations. FPS minimum/average/1%low: 0.999/5.858/1.040. True process mean/max: 138.573/961.220ms. Maximum individual physics step mean/max: 5.423/20.732ms. GPU mean: 29.251ms; draws mean: 2203.75.

Owner20 FPS floor FAIL. Trace unset restores the earlier baseline instrumentation configuration; one sequential pair cannot isolate instrumentation overhead from run variance. All raw rows/logs/PNGs/callbacks/command archived with hashes. Independent completed-case review pending.
