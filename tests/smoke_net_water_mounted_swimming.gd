extends "res://tests/smoke_net_water_swimming.gd"
# peers: 2
## Two real Water peers, one owned Aquaryn. Explicit Stone/saddle/party fixture;
## actual input movement and real dismount/remount, without reconnect/Alpha claim.
func _run() -> void:
	heartbeat_silence_tolerance_s=60.0
	if not await launch(2,"water"):
		quit(await finish())
		return
	if not _pass(await step(0,"host",{}),"host Water"):
		quit(await finish())
		return
	var host_session: Dictionary=await probe(0,"session")
	if not _pass(await step(1,"join",{"host":"127.0.0.1","port":int(host_session.enet_port)}),"join Water"):
		quit(await finish())
		return
	for peer in 2:
		if not _pass(await step(peer,"expect_peers",{"count":2}),"both peer registries ready"):
			quit(await finish())
			return
	var client_session: Dictionary=await probe(1,"session")
	var owner:=str(int(client_session.peer_id))
	if not _pass(await step(0,"water_fixture",{"mode":"island","island_id":"first_shore"}),"SETUP host dry shore"):
		quit(await finish())
		return
	if not _pass(await step(1,"water_mount_fixture",{"species":"water_aquaryn"}),"SETUP client Stone, saddle and owned Aquaryn"):
		quit(await finish())
		return
	if not _pass(await step(1,"ride_mount",{}),"production mount"):
		quit(await finish())
		return
	var before: Dictionary=await probe(1,"water_mounted")
	check(float(before.owned_mount.energy)==20.0,"positive combat energy fixture")
	check(before.local.user_data_dir != (await probe(0,"water_mounted")).local.user_data_dir,"isolated peer user data")
	if not _pass(await step(1,"water_mounted_swim",{}),"start actual mounted input"):
		quit(await finish())
		return
	var saw_mount:=false
	var saw_rider:=false
	var saw_spent:=false
	var saw_matching_owner:=false
	var completed: Dictionary={}
	var observer: Dictionary={}
	for _sample in 35:
		await step(0,"wait",{"frames":45})
		observer=await probe(0,"water_mounted")
		var remote: Dictionary=observer.get("remote_mounts",{}).get(owner,{})
		var packet: Dictionary=remote.get("applied_aquatic",{})
		var rider: Dictionary=observer.get("remote",{}).get(owner,{}).get("applied_aquatic",{})
		saw_mount=saw_mount or int(packet.get("mode",-1))==2
		saw_rider=saw_rider or int(rider.get("mode",-1))==2
		saw_spent=saw_spent or (float(packet.get("stamina_fraction",1.0))<0.99 and float(packet.get("stamina_fraction",0.0))>0.0)
		saw_matching_owner=saw_matching_owner or (int(remote.get("owner_peer_id",0))==int(owner) and int(remote.get("authority",0))==int(owner) and int(packet.get("owner_peer_id",0))==int(owner))
		completed=await probe(1,"water_mounted")
		if not bool(completed.get("motion",{}).get("running",true)):
			break
	check(saw_mount,"host applied owned mount MOUNTED swimming state")
	check(saw_rider,"host applied matching trainer MOUNTED swimming state")
	check(saw_spent,"host observed spent nonzero creature swim resource")
	check(saw_matching_owner,"mount authority and aquatic owner match client")
	check(bool(completed.motion.completed) and str(completed.motion.failure).is_empty(),"actual input completed Water mounted leg: %s" % completed.motion)
	check(float(completed.motion.distance_m)>=30.0,"actual mounted Water displacement at least30m")
	check(is_equal_approx(float(completed.owned_mount.energy),20.0),"swimming preserves positive combat energy")
	check(float(completed.local.stamina)>=float(before.local.stamina)-0.01,"human stamina not spent while mounted")
	if not failures.is_empty():
		quit(await finish())
		return
	await step(0,"wait",{"frames":90})
	observer=await probe(0,"water_mounted")
	completed=await probe(1,"water_mounted")
	var mount: Dictionary=observer.remote_mounts.get(owner,{})
	var drawn: Dictionary=observer.riding.remote.get(owner,{})
	check(float(mount.get("seat_error_m",-1.0))>=0.0 and float(mount.get("seat_error_m",99.0))<=0.35,"host rider stays on actual transformed mount seat")
	check(bool(drawn.get("seated",false)) and bool(drawn.get("mount_saddle_worn",false)),"host presents seated rider and installed saddle")
	check(absf(float(mount.get("applied_aquatic",{}).get("stamina_fraction",-1.0))-float(completed.owned_mount.swim_stamina_fraction))<0.03,"remote resource tracks owned creature")
	if not _pass(await step(1,"water_mount_fixture",{"exhausted":true}),"SETUP exhausted owned swim resource"):
		quit(await finish())
		return
	await step(0,"wait",{"frames":60})
	var drowning: Dictionary=await probe(0,"water_mounted")
	check(bool(drowning.remote_mounts.get(owner,{}).get("applied_aquatic",{}).get("drowning",false)),"host observes mount drowning")
	if not _pass(await step(1,"ride_dismount",{"settle":8}),"production deepwater dismount"):
		quit(await finish())
		return
	await step(0,"wait",{"frames":60})
	var off: Dictionary=await probe(0,"water_mounted")
	check(not bool(off.riding.remote.get(owner,{}).get("riding",true)),"host clears rider mounting state")
	check(int(off.remote.get(owner,{}).get("applied_aquatic",{}).get("mode",-1))==1,"host reconstructs dismounted HUMAN swimmer")
	if not _pass(await step(1,"water_remount",{}),"actual nearby remount without fixture teleport"):
		quit(await finish())
		return
	await step(0,"wait",{"frames":60})
	var remount: Dictionary=await probe(0,"water_mounted")
	var owned: Dictionary=await probe(1,"water_mounted")
	check(bool(remount.riding.remote.get(owner,{}).get("riding",false)),"host restores mounted rider")
	check(is_zero_approx(float(owned.owned_mount.swim_stamina_fraction)),"remount does not refill exhausted resource")
	check(int(remount.remote_mounts.get(owner,{}).get("applied_aquatic",{}).get("mode",-1))==2,"host restores mounted aquatic state")
	print("Water mounted network scope: real two-peer input, rider/mount identity and seat, owned resources, drowning and dismount/remount; fixtures do not prove Alpha, crafting, save or reconnect")
	quit(await finish())
