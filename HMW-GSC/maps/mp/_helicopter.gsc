#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include scripts\utility;
#define H2_CHOPPER_CINEMATIC 0

h2_choppergunner(chopper) {
  self endon("disconnect");

  self setclientomnvar("ui_chopper_enabled", 1);
  self setclientomnvar("fov_scale", 1.09999);

  if(isBot(self))
    self thread scripts\mp\bot_patches::bot_remote_use(chopper);

  var_3 = 200;
  var_4 = 200;
  var_5 = var_3 / 2;
  var_6 = var_4 / 2;

  var_7 = newclienthudelem(self);
  var_7.horzalign = "center";
  var_7.vertalign = "middle";
  var_7.x -= var_5;
  var_7.y -= var_6;
  var_7.archived = true;
  var_7 setshader("h2_overlays_predator_reticle", var_3, var_4);

  chopper waittill("helicopter_done");

  self setclientomnvar("fov_scale", 1);
  self setclientomnvar("ui_chopper_enabled", 0);
  var_7 destroy();
}

init() {
  path_start = getentorstructarray("heli_start", "targetname"); // start pointers, point to the actual start node on path
  loop_start = getentorstructarray("heli_loop_start", "targetname"); // start pointers for loop path in the map

  if(!path_start.size && !loop_start.size)
    return;

  level.heli_types = [];
  level.helis = [];

  precacheHelicopter("h1_vehicle_mi24_hind", "hind");
  precacheHelicopter("vehicle_apache", "apache");
  precacheHelicopter("vehicle_pavelow", "pavelow");
  precacheHelicopter("vehicle_little_bird_armed", "cobra");

  //precacheitem( "cobra_20mm_mp" );
  //precacheitem( "cobra_player_minigun_mp" );
  //precacheitem( "hind_ffar_mp" );
  precacheVehicle("cobra_mp");
  precacheVehicle("cobra_minigun_mp");
  precacheVehicle("pavelow_mp");
  precacheTurret("pavelow_minigun_mp");
  precacheModel("weapon_minigun");
  precacheString( & "MP_CIVILIAN_AIR_TRAFFIC");

  level.h2_chopper_fire_fx = loadfx("fx/muzzleflashes/minigun_flash");

  level.chopper = undefined;

  // array of paths, each element is an array of start nodes that all leads to a single destination node
  level.heli_start_nodes = getentorstructArray("heli_start", "targetname");
  assertEx(level.heli_start_nodes.size, "No \"heli_start\" nodes found in map!");

  level.heli_loop_nodes = getentorstructArray("heli_loop_start", "targetname");
  assertEx(level.heli_loop_nodes.size, "No \"heli_loop_start\" nodes found in map!");

  level.heli_leave_nodes = getentorstructArray("heli_leave", "targetname");
  assertEx(level.heli_leave_nodes.size, "No \"heli_leave\" nodes found in map!");

  level.heli_crash_nodes = getentorstructArray("heli_crash_start", "targetname");
  assertEx(level.heli_crash_nodes.size, "No \"heli_crash_start\" nodes found in map!");

  level.heli_missile_rof = 5; // missile rate of fire, one every this many seconds per target, could fire two at the same time to different targets
  level.heli_maxhealth = 1500; // max health of the helicopter
  level.heli_debug = 0; // debug mode, draws debugging info on screen

  level.heli_targeting_delay = 0.5; // targeting delay
  level.heli_turretReloadTime = 1.5; // mini-gun reload time
  level.heli_turretClipSize = 40; // mini-gun clip size, rounds before reload
  level.heli_visual_range = 3500; // distance radius helicopter will acquire targets (see)

  level.heli_target_spawnprotection = 5; // players are this many seconds safe from helicopter after spawn
  level.heli_target_recognition = 0.5; // percentage of the player's body the helicopter sees before it labels him as a target
  level.heli_missile_friendlycare = 256; // if friendly is within this distance of the target, do not shoot missile
  level.heli_missile_target_cone = 0.3; // dot product of vector target to helicopter forward, 0.5 is in 90 range, bigger the number, smaller the cone
  level.heli_armor_bulletdamage = 0.3; // damage multiplier to bullets onto helicopter's armor

  level.heli_attract_strength = 1000;
  level.heli_attract_range = 4096;

  level.heli_angle_offset = 90;
  level.heli_forced_wait = 0;

  // helicopter fx
  level.chopper_fx["explode"]["death"] = [];
  level.chopper_fx["explode"]["large"] = loadfx("fx/explosions/aerial_explosion_large");
  level.chopper_fx["explode"]["medium"] = loadfx("fx/explosions/aerial_explosion");
  level.chopper_fx["smoke"]["trail"] = loadfx("vfx/trail/trail_smk_white_heli");
  level.chopper_fx["fire"]["trail"]["medium"] = loadfx("vfx/trail/trail_smk_black_heli");
  level.chopper_fx["fire"]["trail"]["large"] = loadfx("vfx/trail/trail_fire_smoke_l");

  level.chopper_fx["damage"]["light_smoke"] = loadfx("vfx/trail/trail_smk_white_heli");
  level.chopper_fx["damage"]["heavy_smoke"] = loadfx("fx/smoke/smoke_trail_black_heli");
  level.chopper_fx["damage"]["on_fire"] = loadfx("fx/fire/fire_smoke_trail_l");

  level.chopper_fx["light"]["left"] = loadfx("fx/misc/aircraft_light_wingtip_green");
  level.chopper_fx["light"]["right"] = loadfx("fx/misc/aircraft_light_wingtip_red");
  level.chopper_fx["light"]["belly"] = loadfx("fx/misc/aircraft_light_red_blink");
  level.chopper_fx["light"]["tail"] = loadfx("fx/misc/aircraft_light_white_blink");

  level.fx_heli_dust = loadfx("fx/treadfx/heli_dust_default");
  level.fx_heli_water = loadfx("fx/treadfx/heli_water");

  makeHeliType("cobra", "fx/explosions/helicopter_explosion_cobra", ::defaultLightFX);
  addAirExplosion("cobra", "fx/explosions/aerial_explosion_large");

  makeHeliType("pavelow", "fx/explosions/helicopter_explosion_cobra", ::pavelowLightFx);
  addAirExplosion("pavelow", "fx/explosions/aerial_explosion_large");

  makeHeliType("mi28", "fx/explosions/helicopter_explosion_cobra", ::defaultLightFX);
  addAirExplosion("mi28", "fx/explosions/aerial_explosion_large");

  makeHeliType("hind", "fx/explosions/helicopter_explosion_cobra", ::defaultLightFX);
  addAirExplosion("hind", "fx/explosions/aerial_explosion_large");

  makeHeliType("apache", "fx/explosions/helicopter_explosion_cobra", ::defaultLightFX);
  addAirExplosion("apache", "fx/explosions/aerial_explosion_large");

  makeHeliType("littlebird", "fx/explosions/helicopter_explosion_cobra", ::defaultLightFX);
  addAirExplosion("littlebird", "fx/explosions/aerial_explosion_large");

  //makeHeliType( "harrier", "explosions/harrier_exposion_ground", ::defaultLightFX );


  level.killstreakFuncs["helicopter_mp"] = ::useHelicopter;
  //level.killstreakFuncs["helicopter_blackbox"] = ::useHelicopterBlackbox;
  level.killstreakFuncs["pavelow_mp"] = ::useHelicopterFlares;
  level.killstreakFuncs["chopper_gunner_mp"] = ::useHelicopterMinigun;
  //level.killstreakFuncs["helicopter_mk19"] = ::useHelicopterMK19;

  level.heliDialog["tracking"][0] = "ac130_fco_moreenemy";
  level.heliDialog["tracking"][1] = "ac130_fco_getthatguy";
  level.heliDialog["tracking"][2] = "ac130_fco_guyrunnin";
  level.heliDialog["tracking"][3] = "ac130_fco_gotarunner";
  level.heliDialog["tracking"][4] = "ac130_fco_personnelthere";
  level.heliDialog["tracking"][5] = "ac130_fco_rightthere";
  level.heliDialog["tracking"][6] = "ac130_fco_tracking";

  level.heliDialog["locked"][0] = "ac130_fco_lightemup";
  level.heliDialog["locked"][1] = "ac130_fco_takehimout";
  level.heliDialog["locked"][2] = "ac130_fco_nailthoseguys";

  level.lastHeliDialogTime = 0;

  queueCreate("helicopter");
}

getentorstructarray(var_0, var_1) {
  var_2 = getstructarray(var_0, var_1);
  var_3 = getentarray(var_0, var_1);

  if(isDefined(var_3) && var_3.size > 0)
    var_2 = array_combine(var_2, var_3);

  return var_2;
}

getentorstruct(var_0, var_1) {
  var_2 = getent(var_0, var_1);

  if(isdefined(var_2))
    return var_2;

  return getstruct(var_0, var_1);
}

makeHeliType(heliType, deathFx, lightFXFunc) {
  level.chopper_fx["explode"]["death"][heliType] = loadFx(deathFX);
  level.lightFxFunc[heliType] = lightFXFunc;
}

addAirExplosion(heliType, explodeFx) {
  level.chopper_fx["explode"]["air_death"][heliType] = loadFx(explodeFx);
}

pavelowLightFX() {
  playFXOnTag(level.chopper_fx["light"]["left"], self, "tag_light_L_wing1");
  wait(0.05);
  playFXOnTag(level.chopper_fx["light"]["right"], self, "tag_light_R_wing1");
  wait(0.05);
  playFXOnTag(level.chopper_fx["light"]["belly"], self, "tag_light_belly");
  wait(0.05);
  playFXOnTag(level.chopper_fx["light"]["tail"], self, "tag_light_tail");
  wait(0.05);
  playFXOnTag(level.chopper_fx["light"]["tail"], self, "tag_light_tail2");
  wait(0.05);
  playFXOnTag(level.chopper_fx["light"]["belly"], self, "tag_light_cockpit01");
}


defaultLightFX() {
  playFXOnTag(level.chopper_fx["light"]["left"], self, "tag_light_L_wing");
  wait(0.05);
  playFXOnTag(level.chopper_fx["light"]["right"], self, "tag_light_R_wing");
  wait(0.05);
  playFXOnTag(level.chopper_fx["light"]["belly"], self, "tag_light_belly");
  wait(0.05);
  playFXOnTag(level.chopper_fx["light"]["tail"], self, "tag_light_tail");
}


useHelicopter(lifeId) {
  return tryUseHelicopter(lifeId);
}

useHelicopterBlackbox(lifeId) {
  return tryUseHelicopter(lifeId, "blackbox");
}

useHelicopterFlares(lifeId) {
  return tryUseHelicopter(lifeId, "flares");
}


useHelicopterMinigun(lifeId) {
  return tryUseHelicopter(lifeId, "minigun");
}


useHelicopterMK19(lifeId) {
  return tryUseHelicopter(lifeId, "mk19");
}


tryUseHelicopter(lifeId, heliType) {
  if(isDefined(level.civilianJetFlyBy)) {
    self iprintlnbold( & "MP_CIVILIAN_AIR_TRAFFIC");
    return false;
  }

  if((!isDefined(heliType) || heliType == "flares") && isDefined(level.chopper)) {
    self iprintlnbold( & "LUA_KS_UNAVAILABLE_AIRSPACE_QUEUE");

    if(isDefined(heliType))
      streakName = "pavelow_mp";
    else
      streakName = "helicopter_mp";

    self maps\mp\gametypes\_hardpoints::shuffleKillStreaksFILO(streakName);

    queueEnt = spawn("script_origin", (0, 0, 0));
    queueEnt hide();
    queueEnt thread deleteOnEntNotify(self, "disconnect");
    queueEnt.player = self;
    queueEnt.lifeId = lifeId;
    queueEnt.heliType = heliType;
    queueEnt.streakName = streakName;

    queueAdd("helicopter", queueEnt);

    return false;
  } else if(isDefined(level.chopper)) {
    self iprintlnbold( & "LUA_KS_UNAVAILABLE_AIRSPACE");
    return false;
  }

  if(isDefined(heliType) && heliType == "minigun") {
    self setUsingRemote("helicopter_" + heliType);
    result = self maps\mp\h2_killstreaks\_common::initRideKillstreak();

    if(result != "success") {
      if(result != "disconnect")
        self clearUsingRemote();

      return false;
    }

    if(isDefined(level.chopper)) {
      self clearUsingRemote();
      self iprintlnbold( & "LUA_KS_UNAVAILABLE_AIRSPACE");
      return false;
    }
  }

  self startHelicopter(lifeId, heliType);
  return true;
}


deleteOnEntNotify(ent, notifyString) {
  self endon("death");
  ent waittill(notifyString);

  self delete();
}


startHelicopter(lifeId, heliType) {
  if(!isDefined(heliType))
    heliType = "";

  switch (heliType) {
    case "minigun":
      eventType = "chopper_gunner_mp";
      break;
    case "flares":
    default:
      eventType = "helicopter_mp";
      break;
  }

  team = self.pers["team"];

  startNode = level.heli_start_nodes[randomInt(level.heli_start_nodes.size)];

  self maps\mp\_matchdata::logKillstreakEvent(eventType, self.origin);

  thread heli_think(lifeId, self, startnode, self.pers["team"], heliType);
}


precacheHelicopter(model, heliType) {
  deathfx = loadfx("fx/explosions/tanker_explosion");

  precacheModel(model);

  level.heli_types[model] = heliType;

  /******************************************************/
  /*					SETUP WEAPON TAGS				*/
  /******************************************************/

  level.cobra_missile_models = [];
  level.cobra_missile_models["cobra_Hellfire"] = "projectile_hellfire_missile";

  precachemodel(level.cobra_missile_models["cobra_Hellfire"]);

  // helicopter sounds:
  level.heli_sound["allies"]["hit"] = "h1_ks_chopper_damage_exp";
  level.heli_sound["allies"]["hitsecondary"] = "h1_ks_chopper_damage_exp";
  level.heli_sound["allies"]["damaged"] = "cobra_helicopter_damaged";
  level.heli_sound["allies"]["spinloop"] = "h1_ks_chopper_death_spin_mid";
  level.heli_sound["allies"]["spinstart"] = "cobra_helicopter_dying_layer";
  level.heli_sound["allies"]["crash"] = "h1_ks_chopper_crash_mid";
  level.heli_sound["allies"]["missilefire"] = "h1_ks_chopper_missile_shot";
  level.heli_sound["axis"]["hit"] = "h1_ks_chopper_damage_exp";
  level.heli_sound["axis"]["hitsecondary"] = "h1_ks_chopper_damage_exp";
  level.heli_sound["axis"]["damaged"] = "hind_helicopter_damaged";
  level.heli_sound["axis"]["spinloop"] = "h1_ks_chopper_death_spin_mid";
  level.heli_sound["axis"]["spinstart"] = "hind_helicopter_dying_layer";
  level.heli_sound["axis"]["crash"] = "h1_ks_chopper_crash_mid";
  level.heli_sound["axis"]["missilefire"] = "h1_ks_chopper_missile_shot";
}


spawn_helicopter(owner, origin, angles, vehicleType, modelName) {
  chopper = spawnHelicopter(owner, origin, angles, vehicleType, modelName);

  if(!isDefined(chopper))
    return undefined;

  if(modelName == "vehicle_pavelow")
    chopper thread maps\mp\h2_killstreaks\_common::h2_sound_ent("pavelow_engine_high");
  else
    chopper thread maps\mp\h2_killstreaks\_common::h2_sound_ent("h1_ks_chopper_cobra_mid");

  if(isdefined(level.heli_types[modelName])) {
    chopper_heli_type = level.heli_types[modelName];
    if(isdefined(level.lightFxFunc[chopper_heli_type])) {
      chopper thread[[level.lightFxFunc[chopper_heli_type]]]();
    }
  }

  chopper addToHeliList();

  chopper.zOffset = (0, 0, chopper getTagOrigin("tag_origin")[2] - chopper getTagOrigin("tag_ground")[2]);
  chopper.attractor = Missile_CreateAttractorEnt(chopper, level.heli_attract_strength, level.heli_attract_range);

  if(vehicleType == "cobra_minigun_mp")
    chopper.zOffset += (0, 0, 1500);

  chopper.damageCallback = ::Callback_VehicleDamage;

  return chopper;
}


heliRide(lifeId, chopper) {
  self endon("disconnect");
  chopper endon("helicopter_done");

  thread teamPlayerCardSplash("callout_used_chopper_gunner", self);
  chopper setVehWeapon("cobra_player_minigun_mp");
  self.heliRideLifeId = lifeId;

  if(self getCurrentWeapon() != "chopper_gunner_mp" || self isSwitchingWeapon()) //force switching back to the laptop to keep the FOV
    self setSpawnWeapon("chopper_gunner_mp");

  self _disableWeaponSwitch();
  self thread endRideOnHelicopterDone(chopper);

  self _visionsetnakedforplayer("black_bw", 0);
  self _visionsetnakedforplayer("", 1);

  chopper.playerView = spawn("script_model", chopper localToWorldCoords((-700, 0, -50)));
  chopper.playerView setModel("tag_origin");
  chopper.playerView.angles = chopper.angles;

  if(H2_CHOPPER_CINEMATIC) {
    self playerLinkWeaponviewToDelta(chopper.playerView, "tag_player", 1.0, 0, 0, 0, 0, true);

    wait 0.5;

    chopper.playerView moveTo(chopper localToWorldCoords((0, 500, -50)), 2);
    chopper.playerView rotateTo(chopper.angles + (0, -90, 0), 2);

    wait 2;

    chopper.playerView moveTo(chopper localToWorldCoords((130, 150, -50)), 1);

    wait 1;

    self _visionsetnakedforplayer("end_game2", 0);
    self _visionsetnakedforplayer("", 1);
    self unlink();

    wait 0.05;

    chopper notify("camera_ready");
  }

  chopper.playerView linkTo(chopper, "tag_player", (-70, 0, -100), (0, 0, 0));
  //self RemoteCameraSoundscapeOn();
  self thread h2_choppergunner(chopper);
  self ThermalVisionFOFOverlayOn();
  self PlayerLinkWeaponviewToDelta(chopper.playerView, "tag_player", 1.0, 180, 180, 0, 180, true);
  self thread maps\mp\h2_killstreaks\_common::thermalVision(chopper, "helicopter_done");
  if(getDvarInt("camera_thirdPerson"))
    self setThirdPersonDOF(false);

  chopper.controlled = true;
  chopper VehicleTurretControlOn(self);
  chopper.gunner = self;

  //self thread weaponLockThink( chopper );

  while (true) {
    chopper waittill("turret_fire");
    chopper fireWeapon();

    foreach(player in level.players) {
      if(player == self)
        chopper playSoundToPlayer("h2_chopgunner_20mm_fire_plr", player);
      else
        chopper playSoundToPlayer("h2_chopgunner_20mm_fire_npc", player);
    }

    position = BulletTrace(chopper.playerView.origin, vector_multiply(anglestoforward(self getPlayerAngles()), 1000000), 0, self)["position"];

    playFX(level.h2_chopper_fire_fx, chopper getTagOrigin("tag_flash"));
    playFX(level.h2_chopper_fire_fx, position);

    earthquake(0.15, 1, chopper.origin, 1000);
  }
}


weaponLockThink(chopper) {
  self endon("disconnect");
  chopper endon("helicopter_done");
  level endon("game_ended");

  for (;;) {
    eyePos = chopper.playerView.origin; //self geteye() doesn't work well with remote killstreaks in h1
    trace = bulletTrace(eyePos, eyePos + (anglesToForward(self getPlayerAngles()) * 100000), 1, self);

    targetListLOS = [];
    targetListNoLOS = [];
    foreach(player in level.players) {
      if(!isAlive(player))
        continue;

      if(level.teamBased && player.team == self.team)
        continue;

      if(player == self)
        continue;

      if(player _hasPerk("specialty_radarimmune"))
        continue;

      if(isDefined(player.spawntime) && (getTime() - player.spawntime) / 1000 <= 5)
        continue;

      player.remoteHeliLOS = true;
      if(!bulletTracePassed(eyePos, player.origin + (0, 0, 32), false, chopper)) {
        //if( distance( player.origin, trace["position"] ) > 256 )
        //	continue;

        targetListNoLOS[targetListNoLOS.size] = player;
      } else {
        targetListLOS[targetListLOS.size] = player;
      }
    }

    targetsInReticle = [];

    /*
    foreach ( target in targetList )
    {
    insideReticle = self WorldPointInReticle_Circle( target.origin, 65, 1200 );

    if( !insideReticle )
    continue;

    targetsInReticle[targetsInReticle.size] = target;
    }
    */

    targetsInReticle = targetListLOS;
    foreach(target in targetListNoLos) {
      targetListLOS[targetListLOS.size] = target;
    }

    if(targetsInReticle.size != 0) {
      sortedTargets = SortByDistance(targetsInReticle, trace["position"]);

      if(distance(sortedTargets[0].origin, trace["position"]) < 384 && sortedTargets[0] DamageConeTrace(trace["position"])) {
        self weaponLockFinalize(sortedTargets[0]);
        heliDialog("locked");
      } else {
        self weaponLockStart(sortedTargets[0]);
        heliDialog("tracking");
      }
    } else {
      self weaponLockFree();
    }

    wait(0.05);
  }
}


heliDialog(dialogGroup) {
  /*
  if( getTime() - level.lastHeliDialogTime < 6000 )
  return;

  level.lastHeliDialogTime = getTime();

  randomIndex = randomInt( level.heliDialog[ dialogGroup ].size );
  soundAlias = level.heliDialog[ dialogGroup ][ randomIndex ];

  fullSoundAlias = maps\mp\gametypes\_teams::getTeamVoicePrefix( self.team ) + soundAlias;

  self playLocalSound( fullSoundAlias );
  */
  //TODO - add these sounds later
}


endRide(chopper) {
  self RemoteCameraSoundscapeOff();
  self ThermalVisionOff();
  self ThermalVisionFOFOverlayOff();
  self unlink();
  self clearUsingRemote();
  self _enableWeaponSwitch();

  if(getDvarInt("camera_thirdPerson"))
    self setThirdPersonDOF(true);

  weaponList = self GetWeaponsListExclusives();
  foreach(weapon in weaponList)
  self takeWeapon(weapon);

  if(isDefined(chopper) && isDefined(chopper.controlled))
    chopper VehicleTurretControlOff(self);

  chopper.playerView delete();

  self _visionsetnakedforplayer("black_bw", 0);
  self _visionsetnakedforplayer("", 1);
  self thread maps\mp\h2_killstreaks\_common::takeKillstreakWeapons();
  self notify("heliPlayer_removed");
}


endRideOnHelicopterDone(chopper) {
  self endon("disconnect");

  chopper waittill("helicopter_done");

  self endRide(chopper);
}


getPosNearEnemies() {
  validEnemies = [];

  foreach(player in level.players) {
    if(player.team == "spectator")
      continue;

    if(player.team == self.team)
      continue;

    if(!isAlive(player))
      continue;

    if(!bulletTracePassed(player.origin, player.origin + (0, 0, 2048), false, player))
      continue;

    player.remoteHeliDist = 0;
    validEnemies[validEnemies.size] = player;
  }

  if(!validEnemies.size)
    return undefined;

  for (i = 0; i < validEnemies.size; i++) {
    for (j = i + 1; j < validEnemies.size; j++) {
      dist = distanceSquared(validEnemies[i].origin, validEnemies[j].origin);

      validEnemies[i].remoteHeliDist += dist;
      validEnemies[j].remoteHeliDist += dist;
    }
  }

  bestPlayer = validEnemies[0];
  foreach(player in validEnemies) {
    if(player.remoteHeliDist < bestPlayer.remoteHeliDist)
      bestPlayer = player;
  }

  return (bestPlayer.origin);
}


updateAreaNodes(areaNodes) {
  validEnemies = [];

  foreach(node in areaNodes) {
    node.validPlayers = [];
    node.nodeScore = 0;
  }

  foreach(player in level.players) {
    if(!isAlive(player))
      continue;

    if(player.team == self.team)
      continue;

    foreach(node in areaNodes) {
      if(distanceSquared(player.origin, node.origin) > 1048576)
        continue;

      node.validPlayers[node.validPlayers.size] = player;
    }
  }

  bestNode = areaNodes[0];
  foreach(node in areaNodes) {
    heliNode = getentorstruct(node.target, "targetname");
    foreach(player in node.validPlayers) {
      node.nodeScore += 1;

      if(bulletTracePassed(player.origin + (0, 0, 32), heliNode.origin, false, player))
        node.nodeScore += 3;
    }

    if(node.nodeScore > bestNode.nodeScore)
      bestNode = node;
  }

  return (getentorstruct(bestNode.target, "targetname"));
}


// spawn helicopter at a start node and monitors it
heli_think(lifeId, owner, startnode, heli_team, heliType) {
  heliOrigin = startnode.origin;
  heliAngles = startnode.angles;

  switch (heliType) {
    case "minigun":
      vehicleType = "cobra_minigun_mp";
      vehicleModel = "h1_vehicle_mi24_hind";
      break;

    case "flares":
      vehicleType = "pavelow_mp";
      vehicleModel = "vehicle_pavelow";
      break;

    default:
      vehicleType = "cobra_mp";
      vehicleModel = "vehicle_cobra_helicopter_fly";
      break;
  }

  chopper = spawn_helicopter(owner, heliOrigin, heliAngles, vehicleType, vehicleModel);

  if(!isDefined(chopper))
    return;

  level.chopper = chopper;
  chopper.heliType = heliType;
  chopper.lifeId = lifeId;
  chopper.team = heli_team;
  chopper.pers["team"] = heli_team;
  chopper.owner = owner;

  if(heliType == "flares")
    chopper.maxhealth = level.heli_maxhealth * 2; // max health
  else
    chopper.maxhealth = level.heli_maxhealth; // max health

  chopper.targeting_delay = level.heli_targeting_delay; // delay between per targeting scan - in seconds
  chopper.primaryTarget = undefined; // primary target ( player )
  chopper.secondaryTarget = undefined; // secondary target ( player )
  chopper.attacker = undefined; // last player that shot the helicopter
  chopper.currentstate = "ok"; // health state

  if(heliType == "flares" || heliType == "minigun")
    chopper thread heli_flares_monitor();

  // helicopter loop threads
  chopper thread heli_leave_on_disconnect(owner);
  chopper thread heli_leave_on_changeTeams(owner);
  chopper thread heli_leave_on_gameended(owner);
  chopper thread heli_damage_monitor(); // monitors damage
  chopper thread heli_health(); // display helicopter's health through smoke/fire
  chopper thread heli_existance();

  // flight logic
  chopper endon("helicopter_done");
  chopper endon("crashing");
  chopper endon("leaving");
  chopper endon("death");

  // initial fight into play space	
  if(heliType == "minigun") {
    owner thread heliRide(lifeId, chopper);
    chopper thread heli_leave_on_spawned(owner);
  }

  attackAreas = getentorstructArray("heli_attack_area", "targetname");
  //attackAreas = [];
  loopNode = level.heli_loop_nodes[randomInt(level.heli_loop_nodes.size)];

  // specific logic per type
  switch (heliType) {
    case "minigun":
      chopper thread heli_targeting();
      if(H2_CHOPPER_CINEMATIC)
        chopper waittill("camera_ready");
      chopper heli_fly_simple_path(startNode);
      chopper thread heli_leave_on_timeout(40.0);
      if(attackAreas.size)
        chopper thread heli_fly_well(attackAreas);
      else
        chopper thread heli_fly_loop_path(loopNode);
      break;
    case "flares":
      thread teamPlayerCardSplash("callout_used_pavelow", owner);
      chopper thread makeGunShip();
      chopper heli_fly_simple_path(startNode);
      chopper thread heli_leave_on_timeout(60.0);
      chopper thread heli_fly_loop_path(loopNode);
      break;
    default:
      chopper thread attack_targets();
      chopper thread heli_targeting();
      chopper heli_fly_simple_path(startNode);
      chopper thread heli_leave_on_timeout(60.0);
      chopper thread heli_fly_loop_path(loopNode);
      break;
  }
}


makeGunShip() {
  self endon("death");
  self endon("helicopter_done");

  wait(0.5);

  mgTurret = spawnTurret("misc_turret", self.origin, "pavelow_minigun_mp");
  mgTurret.lifeId = self.lifeId;
  mgTurret linkTo(self, "tag_gunner_left", (0, 0, 0), (0, 0, 0));
  mgTurret setModel("weapon_minigun");
  mgTurret.owner = self.owner;
  mgTurret.team = self.team;
  mgTurret makeTurretInoperable();
  mgTurret.pers["team"] = self.team;
  mgTurret.killCamEnt = self;
  self.mgTurretLeft = mgTurret;
  self.mgTurretLeft SetDefaultDropPitch(0);

  mgTurret = spawnTurret("misc_turret", self.origin, "pavelow_minigun_mp");
  mgTurret.lifeId = self.lifeId;
  mgTurret linkTo(self, "tag_gunner_right", (0, 0, 0), (0, 0, 0));
  mgTurret setModel("weapon_minigun");
  mgTurret.owner = self.owner;
  mgTurret.team = self.team;
  mgTurret makeTurretInoperable();
  mgTurret.pers["team"] = self.team;
  mgTurret.killCamEnt = self;
  self.mgTurretRight = mgTurret;
  self.mgTurretRight SetDefaultDropPitch(0);

  if(level.teamBased) {
    self.mgTurretLeft setTurretTeam(self.team);
    self.mgTurretRight setTurretTeam(self.team);
  }

  self.mgTurretLeft setMode("auto_nonai");
  self.mgTurretRight setMode("auto_nonai");

  self.mgTurretLeft SetSentryOwner(self.owner);
  self.mgTurretRight SetSentryOwner(self.owner);

  self.mgTurretLeft SetTurretMinimapVisible(false);
  self.mgTurretRight SetTurretMinimapVisible(false);

  self.mgTurretLeft thread sentry_attackTargets();
  self.mgTurretRight thread sentry_attackTargets();

  self thread deleteTurretsWhenDone();
}


deleteTurretsWhenDone() {
  self waittill("helicopter_done");

  self.mgTurretRight delete();
  self.mgTurretLeft delete();
}


sentry_attackTargets() {
  self endon("death");
  self endon("helicopter_done");

  level endon("game_ended");

  for (;;) {
    self waittill("turretstatechange");

    if(self isFiringTurret())
      self thread sentry_burstFireStart();
    else
      self thread sentry_burstFireStop();
  }
}


sentry_burstFireStart() {
  self endon("death");
  self endon("stop_shooting");
  self endon("leaving");

  level endon("game_ended");

  fireTime = 0.1;
  minShots = 40;
  maxShots = 80;
  minPause = 1.0;
  maxPause = 2.0;

  for (;;) {
    numShots = randomIntRange(minShots, maxShots + 1);

    for (i = 0; i < numShots; i++) {
      targetEnt = self getTurretTarget(false);
      if(isDefined(targetEnt) && !targetEnt _hasPerk("specialty_radarimmune") && (!isDefined(targetEnt.spawntime) || (gettime() - targetEnt.spawntime) / 1000 > 5))
        self shootTurret();

      wait(fireTime);
    }

    wait(randomFloatRange(minPause, maxPause));
  }
}


sentry_burstFireStop() {
  self notify("stop_shooting");
}


heli_existance() {
  entityNumber = self getEntityNumber();

  self waittill_any("death", "crashing", "leaving");

  self removeFromHeliList(entityNumber);

  self notify("helicopter_done");

  player = undefined;
  queueEnt = queueRemoveFirst("helicopter");
  if(!isDefined(queueEnt)) {
    level.chopper = undefined;
    return;
  }

  player = queueEnt.player;
  lifeId = queueEnt.lifeId;
  streakName = queueEnt.streakName;
  heliType = queueEnt.heliType;
  queueEnt delete();

  if(isDefined(player) && (player.sessionstate == "playing" || player.sessionstate == "dead")) {
    logstring("hardpoint: " + streakName);
    thread maps\mp\gametypes\_missions::usehardpoint(streakName);
    player thread[[level.onxpevent]]("hardpoint");
    player thread maps\mp\gametypes\_hardpoints::killstreakLeaderDialog(streakName);

    player startHelicopter(lifeId, heliType);
  } else {
    level.chopper = undefined;
  }
}


// helicopter targeting logic
heli_targeting() {
  self endon("death");
  self endon("helicopter_done");
  level endon("game_ended");

  // targeting sweep cycle
  for (;;) {
    // array of helicopter's targets
    targets = [];
    self.primaryTarget = undefined;
    self.secondaryTarget = undefined;

    players = level.players;

    foreach(player in level.players) {
      if(!canTarget_turret(player))
        continue;

      targets[targets.size] = player;
    }

    if(targets.size) {
      targetPlayer = getBestPrimaryTarget(targets);
      self.primaryTarget = targetPlayer;
      self notify("primary acquired");
    }

    if(isDefined(level.harriers)) {
      foreach(harrier in level.harriers) {
        if(!isDefined(harrier))
          continue;

        if((level.teamBased && harrier.team != self.team) || (!level.teamBased && harrier.owner != self.owner)) {
          self notify("secondary acquired");
          self.secondaryTarget = harrier;
        }
      }
    }

    wait(0.5);
  }
}

// targetability
canTarget_turret(player) {
  canTarget = true;

  if(!isAlive(player) || player.sessionstate != "playing")
    return false;

  if(self.heliType != "flares") {
    if(!self Vehicle_CanTurretTargetPoint(player.origin + (0, 0, 40), 1, self))
      return false;
  }

  if(distance(player.origin, self.origin) > level.heli_visual_range)
    return false;

  if(level.teamBased && player.pers["team"] == self.team)
    return false;

  if(player == self.owner)
    return false;

  if(isdefined(player.spawntime) && (gettime() - player.spawntime) / 1000 <= 5)
    return false;

  if(player _hasPerk("specialty_radarimmune"))
    return false;

  heli_centroid = self.origin + (0, 0, -160);
  heli_forward_norm = anglestoforward(self.angles);
  heli_turret_point = heli_centroid + 144 * heli_forward_norm;

  if(player sightConeTrace(heli_turret_point, self) < level.heli_target_recognition)
    return false;

  return canTarget;
}


getBestPrimaryTarget(targets) {
  foreach(player in targets)
  update_player_threat(player);

  // find primary target, highest threat level
  highest = 0;
  primaryTarget = undefined;

  foreach(player in targets) {
    assertEx(isDefined(player.threatlevel), "Target player does not have threat level");

    if(player.threatlevel < highest)
      continue;

    highest = player.threatlevel;
    primaryTarget = player;
  }

  assertEx(isDefined(primaryTarget), "Targets exist, but none was assigned as primary");

  return (primaryTarget);
}


// threat factors
update_player_threat(player) {
  player.threatlevel = 0;

  // distance factor
  dist = distance(player.origin, self.origin);
  player.threatlevel += ((level.heli_visual_range - dist) / level.heli_visual_range) * 100; // inverse distance % with respect to helicopter targeting range

  // behavior factor
  if(isdefined(self.attacker) && player == self.attacker)
    player.threatlevel += 100;

  // player score factor
  player.threatlevel += player.score * 4;

  if(isdefined(player.antithreat))
    player.threatlevel -= player.antithreat;

  if(player.threatlevel <= 0)
    player.threatlevel = 1;
}


// resets helicopter's motion values
heli_reset() {
  self clearTargetYaw();
  self clearGoalYaw();
  self Vehicle_SetSpeed(60, 25);
  self setyawspeed(75, 45, 45);
  //self setjitterparams( (30, 30, 30), 4, 6 );
  self setmaxpitchroll(30, 30);
  self setneargoalnotifydist(256);
  self setturningability(0.9);
}


Callback_VehicleDamage(inflictor, attacker, damage, dFlags, meansOfDeath, weapon, point, dir, hitLoc, timeOffset, modelIndex, partName) {
  if(!isDefined(attacker) || attacker == self)
    return;

  if(!maps\mp\gameTypes\_weapons::attackerCanDamageItem(attacker, self.owner))
    return;

  switch (weapon) {
    case "ac130_105mm_mp":
    case "ac130_40mm_mp":
    case "stinger_mp":
    case "javelin_mp":
    case "remotemissile_projectile_mp":
      self.largeProjectileDamage = true;
      damage = self.maxhealth + 1;
      break;
  }

  if(self.damageTaken + damage >= self.maxhealth) {
    if(weapon == "harrier_FFAR_mp")
      self.largeProjectileDamage = true;

    validAttacker = undefined;

    if(!isDefined(self.owner) || attacker != self.owner)
      validAttacker = attacker;

    if(isDefined(validAttacker)) {
      validAttacker notify("destroyed_killstreak", weapon);
    }
  }

  self Vehicle_FinishDamage(inflictor, attacker, damage, dFlags, meansOfDeath, weapon, point, dir, hitLoc, timeOffset, modelIndex, partName);
}


addRecentDamage(damage) {
  self endon("death");

  self.recentDamageAmount += damage;

  wait(4.0);
  self.recentDamageAmount -= damage;
}


// accumulate damage and react
heli_damage_monitor() {
  self endon("death");
  self endon("crashing");
  self endon("leaving");
  level endon("game_ended");

  self.damageTaken = 0;
  self.recentDamageAmount = 0;

  for (;;) {
    // this damage is done to self.health which isnt used to determine the helicopter's health, damageTaken is.
    self waittill("damage", damage, attacker, direction_vec, P, type);

    assert(isDefined(attacker));

    self.attacker = attacker;

    if(isPlayer(attacker)) {
      attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback("");

      if(type == "MOD_RIFLE_BULLET" || type == "MOD_PISTOL_BULLET") {
        damage *= level.heli_armor_bulletdamage;

        if(attacker _hasPerk("specialty_armorpiercing"))
          damage += damage * level.armorPiercingMod;
      }
    }

    self.damageTaken += damage;

    self thread addRecentDamage(damage);

    if(self.damageTaken > self.maxhealth && ((level.teamBased && self.team != attacker.team) || !level.teamBased)) {
      validAttacker = undefined;
      if(isDefined(attacker.owner) && (!isDefined(self.owner) || attacker.owner != self.owner))
        validAttacker = attacker.owner;
      else if(!isDefined(attacker.owner) && attacker.classname == "script_vehicle")
        return;
      else if(!isDefined(self.owner) || attacker != self.owner)
        validAttacker = attacker;

      if(isDefined(validAttacker)) {
        attacker notify("destroyed_helicopter");

        if(self.heliType == "flares") {
          thread teamPlayerCardSplash("destroyed_pavelow", validAttacker);
          xpVal = 400;
        } else if(self.heliType == "minigun") {
          thread teamPlayerCardSplash("destroyed_chopper_gunner", validAttacker);
          xpVal = 300;
        } else {
          thread teamPlayerCardSplash("destroyed_helicopter", validAttacker);
          xpVal = 200;
        }

        validAttacker thread maps\mp\gametypes\_rank::giveRankXP("kill", xpVal);
        thread maps\mp\gametypes\_missions::vehicleKilled(self.owner, self, undefined, validAttacker, damage, type);

      }
    }
  }
}


heli_health() {
  self endon("death");
  self endon("leaving");
  self endon("crashing");
  level endon("game_ended");

  self.currentstate = "ok";
  self.laststate = "ok";
  self setdamagestage(3);

  damageState = 3;
  self setDamageStage(damageState);

  for (;;) {
    if(self.damageTaken >= (self.maxhealth * 0.33) && damageState == 3) {
      damageState = 2;
      self setDamageStage(damageState);
      self.currentstate = "light smoke";
      playFxOnTag(level.chopper_fx["damage"]["light_smoke"], self, "tag_engine_left");
    } else if(self.damageTaken >= (self.maxhealth * 0.66) && damageState == 2) {
      damageState = 1;
      self setDamageStage(damageState);
      self.currentstate = "heavy smoke";
      stopFxOnTag(level.chopper_fx["damage"]["light_smoke"], self, "tag_engine_left");
      playFxOnTag(level.chopper_fx["damage"]["heavy_smoke"], self, "tag_engine_left");
    } else if(self.damageTaken > self.maxhealth) {
      damageState = 0;
      self setDamageStage(damageState);

      stopFxOnTag(level.chopper_fx["damage"]["heavy_smoke"], self, "tag_engine_left");

      if(IsDefined(self.largeProjectileDamage) && self.largeProjectileDamage) {
        self thread heli_explode();
      } else {
        playFxOnTag(level.chopper_fx["damage"]["on_fire"], self, "tag_engine_left");
        self thread heli_crash();
      }
    }

    wait 0.05;
  }
}


// attach helicopter on crash path
heli_crash() {
  self notify("crashing");

  crashNode = level.heli_crash_nodes[randomInt(level.heli_crash_nodes.size)];

  self thread heli_spin(180);
  self thread heli_secondary_explosions();
  self heli_fly_simple_path(crashNode);

  self thread heli_explode();
}

heli_secondary_explosions() {
  playFxOnTag(level.chopper_fx["explode"]["large"], self, "tag_engine_left");
  self playSound(level.heli_sound[self.team]["hitsecondary"]);

  wait(3.0);

  if(!isDefined(self))
    return;

  playFxOnTag(level.chopper_fx["explode"]["large"], self, "tag_engine_left");
  self playSound(level.heli_sound[self.team]["hitsecondary"]);
}

// self spin at one rev per 2 sec
heli_spin(speed) {
  self endon("death");

  // play hit sound immediately so players know they got it
  self playSound(level.heli_sound[self.team]["hit"]);

  // play heli crashing spinning sound
  self thread spinSoundShortly();
  self thread trail_fx();

  // spins until death
  self setyawspeed(speed, speed, speed);
  while (isdefined(self)) {
    self settargetyaw(self.angles[1] + (speed * 0.9));
    wait(1);
  }
}

trail_fx() {
  self endon("death");
  level endon("game_ended");

  for (;;) {
    wait 0.05;

    playFXOnTag(level.chopper_fx["smoke"]["trail"], self, "tail_rotor_jnt");
    playFXOnTag(level.chopper_fx["fire"]["trail"]["large"], self, "tag_engine_left");
  }
}

spinSoundShortly() {
  self endon("death");

  wait .25;

  self stopLoopSound();
  wait .05;
  self playLoopSound(level.heli_sound[self.team]["spinloop"]);
  wait .05;
  self playLoopSound(level.heli_sound[self.team]["spinstart"]);
}


// crash explosion
heli_explode() {
  self notify("death");

  org = self.origin;
  forward = (self.origin + (0, 0, 1)) - self.origin;
  playFx(level.chopper_fx["explode"]["large"], org, forward);

  // play heli explosion sound
  self playSound(level.heli_sound[self.team]["crash"]);

  // give "death" notify time to process
  wait(0.05);
  self delete();
}


fire_missile(sMissileType, iShots, eTarget) {
  if(!isdefined(iShots))
    iShots = 1;
  assert(self.health > 0);

  weaponName = undefined;
  weaponShootTime = undefined;
  defaultWeapon = "cobra_20mm_mp";
  tags = [];
  switch (sMissileType) {
    case "ffar":
      weaponName = "hind_ffar_mp";

      tags[0] = "tag_store_r_2";
      break;
    default:
      assertMsg("Invalid missile type specified. Must be ffar");
      break;
  }
  assert(isdefined(weaponName));
  assert(tags.size > 0);

  weaponShootTime = weaponfiretime(weaponName);
  assert(isdefined(weaponShootTime));

  self setVehWeapon(weaponName);
  nextMissileTag = -1;
  for (i = 0; i < iShots; i++) // I don't believe iShots > 1 is properly supported; we don't set the weapon each time
  {
    nextMissileTag++;
    if(nextMissileTag >= tags.size)
      nextMissileTag = 0;

    self setVehWeapon("hind_ffar_mp");

    if(isdefined(eTarget)) {
      eMissile = self fireWeapon(tags[nextMissileTag], eTarget);
      eMissile Missile_SetFlightmodeDirect();
      eMissile Missile_SetTargetEnt(eTarget);
    } else {
      eMissile = self fireWeapon(tags[nextMissileTag]);
      eMissile Missile_SetFlightmodeDirect();
      eMissile Missile_SetTargetEnt(eTarget);
    }

    if(i < iShots - 1)
      wait weaponShootTime;
  }
  // avoid calling setVehWeapon again this frame or the client doesn't hear about the original weapon change
}

// checks if owner is valid, returns false if not valid
check_owner() {
  if(!isdefined(self.owner) || !isdefined(self.owner.pers["team"]) || self.owner.pers["team"] != self.team) {
    self thread heli_leave();

    return false;
  }

  return true;
}


heli_leave_on_disconnect(owner) {
  self endon("death");
  self endon("helicopter_done");

  owner waittill("disconnect");

  self thread heli_leave();
}

heli_leave_on_changeTeams(owner) {
  self endon("death");
  self endon("helicopter_done");

  owner waittill_any("joined_team", "joined_spectators");

  self thread heli_leave();
}

heli_leave_on_spawned(owner) {
  self endon("death");
  self endon("helicopter_done");

  owner waittill("spawned");

  self thread heli_leave();
}

heli_leave_on_gameended(owner) {
  self endon("death");
  self endon("helicopter_done");

  level waittill("game_ended");

  self thread heli_leave();
}

heli_leave_on_timeout(timeOut) {
  self endon("death");
  self endon("helicopter_done");

  maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause(timeOut);

  self thread heli_leave();
}

attack_targets() {
  //self thread turret_kill_players();
  self thread attack_primary();
  self thread attack_secondary();
}


// missile only
attack_secondary() {
  self endon("death");
  self endon("crashing");
  self endon("leaving");
  level endon("game_ended");

  for (;;) {
    if(isdefined(self.secondaryTarget)) {
      self.secondaryTarget.antithreat = undefined;
      self.missileTarget = self.secondaryTarget;

      antithreat = 0;

      while (isdefined(self.missileTarget) && isalive(self.missileTarget)) {
        // if selected target is not in missile hit range, skip
        if(self missile_target_sight_check(self.missileTarget))
          self thread missile_support(self.missileTarget, level.heli_missile_rof);
        else
          break;

        self waittill("missile ready");

        // target might disconnect or change during last assault cycle
        if(!isdefined(self.secondaryTarget) || (isdefined(self.secondaryTarget) && self.missileTarget != self.secondaryTarget))
          break;
      }
      // reset the antithreat factor
      if(isdefined(self.missileTarget))
        self.missileTarget.antithreat = undefined;
    }
    self waittill("secondary acquired");

    // check if owner has left, if so, leave
    self check_owner();
  }
}

// check if missile is in hittable sight zone
missile_target_sight_check(missiletarget) {
  heli2target_normal = vectornormalize(missiletarget.origin - self.origin);
  heli2forward = anglestoforward(self.angles);
  heli2forward_normal = vectornormalize(heli2forward);

  heli_dot_target = vectordot(heli2target_normal, heli2forward_normal);

  if(heli_dot_target >= level.heli_missile_target_cone) {
    debug_print3d_simple("Missile sight: " + heli_dot_target, self, (0, 0, -40), 40);
    return true;
  }
  return false;
}

// if wait for turret turning is too slow, enable missile assault support
missile_support(target_player, rof) {
  self endon("death");
  self endon("crashing");
  self endon("leaving");

  if(isdefined(target_player)) {
    if(level.teambased) {
      if(isDefined(target_player.owner) && target_player.team != self.team) {
        self fire_missile("ffar", 1, target_player);
        self notify("missile fired");
      }
    } else {
      if(isDefined(target_player.owner) && target_player.owner != self.owner) {
        self fire_missile("ffar", 1, target_player);
        self notify("missile fired");
      }
    }
  }

  wait(rof);
  self notify("missile ready");

  return;
}

// mini-gun with missile support
attack_primary() {
  self endon("death");
  self endon("crashing");
  self endon("leaving");

  while (1) {
    wait(0.05);

    if(!isAlive(self.primaryTarget))
      continue;

    currentTarget = self.primaryTarget;

    currentTarget.antithreat = 0;

    if(randomInt(5) < 3)
      angle = currentTarget.angles[1] + randomFloatRange(-30, 30);
    else
      angle = randomInt(360);

    radiusOffset = 96;

    xOffset = cos(angle) * radiusOffset;
    yOffset = sin(angle) * radiusOffset;

    self setTurretTargetEnt(currentTarget, (xOffset, yOffset, 40));

    self waitOnTargetOrDeath(currentTarget, 3.0);

    if(!isAlive(currentTarget) || !self Vehicle_CanTurretTargetPoint(currentTarget.origin + (0, 0, 40)))
      continue;

    weaponShootTime = weaponFireTime("cobra_20mm_mp");

    convergenceMod = 1;
    shotsSinceLastSighting = 0;

    self playLoopSound("weap_cobra_20mm_fire_npc");
    for (i = 0; i < level.heli_turretClipSize; i++) {
      self setVehWeapon("cobra_20mm_mp");
      self fireWeapon("tag_flash");

      playFX(level.h2_chopper_fire_fx, self getTagOrigin("tag_flash"));

      if(i < level.heli_turretClipSize - 1)
        wait weaponShootTime;

      if(!isDefined(currentTarget))
        break;

      if(self Vehicle_CanTurretTargetPoint(currentTarget.origin + (0, 0, 40), 1, self)) {
        convergenceMod = max(convergenceMod - 0.05, 0);
        shotsSinceLastSighting = 0;
      } else {
        shotsSinceLastSighting++;
      }

      if(shotsSinceLastSighting > 10)
        break;

      targetPos = ((xOffset * convergenceMod) + randomFloatRange(-6, 6), (yOffset * convergenceMod) + randomFloatRange(-6, 6), 40 + randomFloatRange(-6, 6));

      self setTurretTargetEnt(currentTarget, targetPos);
    }
    self stopLoopSound();

    // lower the target's threat since already assaulted on
    if(isAlive(currentTarget))
      currentTarget.antithreat += 100;

    wait(randomFloatRange(0.5, 2.0));
  }
}

waitOnTargetOrDeath(target, timeOut) {
  self endon("death");
  self endon("helicopter_done");

  target endon("death");
  target endon("disconnect");

  self waittill_notify_or_timeout("turret_on_target", timeOut);
}


fireMissile(missileTarget) {
  self endon("death");
  self endon("crashing");
  self endon("leaving");

  assert(self.health > 0);

  if(!isdefined(missileTarget))
    return;

  if(Distance2D(self.origin, missileTarget.origin) < 512)
    return;

  self setVehWeapon("hind_ffar_mp");
  missile = self fireWeapon("tag_flash", missileTarget);
  missile Missile_SetFlightmodeDirect();
  missile Missile_SetTargetEnt(missileTarget);
}


// ====================================================================================
//								Helicopter Pathing Logic
// ====================================================================================

getOriginOffsets(goalNode) {
  startOrigin = self.origin;
  endOrigin = goalNode.origin;

  numTraces = 0;
  maxTraces = 40;

  traceOffset = (0, 0, -196);

  traceOrigin = physicsTrace(startOrigin + traceOffset, endOrigin + traceOffset);

  while (distance(traceOrigin, endOrigin + traceOffset) > 10 && numTraces < maxTraces) {
    println("trace failed: " + distance(physicsTrace(startOrigin + traceOffset, endOrigin + traceOffset), endOrigin + traceOffset));

    if(startOrigin[2] < endOrigin[2]) {
      startOrigin += (0, 0, 128);
    } else if(startOrigin[2] > endOrigin[2]) {
      endOrigin += (0, 0, 128);
    } else {
      startOrigin += (0, 0, 128);
      endOrigin += (0, 0, 128);
    }

    //thread draw_line( startOrigin+traceOffset, endOrigin+traceOffset, (0,1,9), 200 );
    numTraces++;

    traceOrigin = physicsTrace(startOrigin + traceOffset, endOrigin + traceOffset);
  }

  offsets = [];
  offsets["start"] = startOrigin;
  offsets["end"] = endOrigin;
  return offsets;
}


travelToNode(goalNode) {
  originOffets = getOriginOffsets(goalNode);

  if(originOffets["start"] != self.origin) {
    // motion change via node
    if(isdefined(goalNode.script_airspeed) && isdefined(goalNode.script_accel)) {
      heli_speed = goalNode.script_airspeed;
      heli_accel = goalNode.script_accel;
    } else {
      heli_speed = 30 + randomInt(20);
      heli_accel = 15 + randomInt(15);
    }

    self Vehicle_SetSpeed(heli_speed, heli_accel);
    self setvehgoalpos(originOffets["start"] + (0, 0, 30) + self.zOffset, 0);
    // calculate ideal yaw
    self setgoalyaw(goalNode.angles[1] + level.heli_angle_offset);

    //println( "setting goal to startOrigin" );

    self waittill("goal");
  }

  if(originOffets["end"] != goalNode.origin) {
    // motion change via node
    if(isdefined(goalNode.script_airspeed) && isdefined(goalNode.script_accel)) {
      heli_speed = goalNode.script_airspeed;
      heli_accel = goalNode.script_accel;
    } else {
      heli_speed = 30 + randomInt(20);
      heli_accel = 15 + randomInt(15);
    }

    self Vehicle_SetSpeed(heli_speed, heli_accel);
    self setvehgoalpos(originOffets["end"] + (0, 0, 30) + self.zOffset, 0);
    // calculate ideal yaw
    self setgoalyaw(goalNode.angles[1] + level.heli_angle_offset);

    //println( "setting goal to endOrigin" );

    self waittill("goal");
  }
}


heli_fly_simple_path(startNode) {
  self endon("death");
  self endon("leaving");

  // only one thread instance allowed
  self notify("flying");
  self endon("flying");

  heli_reset();

  currentNode = startNode;
  while (isDefined(currentNode.target)) {
    nextNode = getentorstruct(currentNode.target, "targetname");
    assertEx(isDefined(nextNode), "Next node in path is undefined, but has targetname");

    if(isDefined(currentNode.script_airspeed) && isDefined(currentNode.script_accel)) {
      heli_speed = currentNode.script_airspeed;
      heli_accel = currentNode.script_accel;
    } else {
      heli_speed = 30 + randomInt(20);
      heli_accel = 15 + randomInt(15);
    }

    self Vehicle_SetSpeed(heli_speed, heli_accel);

    // end of the path
    if(!isDefined(nextNode.target)) {
      self setVehGoalPos(nextNode.origin + (self.zOffset), true);
      self waittill("near_goal");
    } else {
      self setVehGoalPos(nextNode.origin + (self.zOffset), false);
      self waittill("near_goal");

      self setGoalYaw(nextNode.angles[1]);

      self waittillmatch("goal");
    }

    currentNode = nextNode;
  }

  printLn(currentNode.origin);
  printLn(self.origin);
}


heli_fly_loop_path(startNode) {
  self endon("death");
  self endon("crashing");
  self endon("leaving");

  // only one thread instance allowed
  self notify("flying");
  self endon("flying");

  heli_reset();

  self thread heli_loop_speed_control(startNode);

  currentNode = startNode;
  while (isDefined(currentNode.target)) {
    nextNode = getentorstruct(currentNode.target, "targetname");
    assertEx(isDefined(nextNode), "Next node in path is undefined, but has targetname");

    if(isDefined(currentNode.script_airspeed) && isDefined(currentNode.script_accel)) {
      self.desired_speed = currentNode.script_airspeed;
      self.desired_accel = currentNode.script_accel;
    } else {
      self.desired_speed = 30 + randomInt(20);
      self.desired_accel = 15 + randomInt(15);
    }

    if(self.heliType == "flares") {
      self.desired_speed *= 0.5;
      self.desired_accel *= 0.5;
    }

    if(isDefined(nextNode.script_delay) && isDefined(self.primaryTarget) && !self heli_is_threatened()) {
      self setVehGoalPos(nextNode.origin + (self.zOffset), true);
      self waittill("near_goal");

      wait(nextNode.script_delay);
    } else {
      self setVehGoalPos(nextNode.origin + (self.zOffset), false);
      self waittill("near_goal");

      self setGoalYaw(nextNode.angles[1]);

      self waittillmatch("goal");
    }

    currentNode = nextNode;
  }
}


heli_loop_speed_control(currentNode) {
  self endon("death");
  self endon("crashing");
  self endon("leaving");

  if(isDefined(currentNode.script_airspeed) && isDefined(currentNode.script_accel)) {
    self.desired_speed = currentNode.script_airspeed;
    self.desired_accel = currentNode.script_accel;
  } else {
    self.desired_speed = 30 + randomInt(20);
    self.desired_accel = 15 + randomInt(15);
  }

  lastSpeed = 0;
  lastAccel = 0;

  while (1) {
    goalSpeed = self.desired_speed;
    goalAccel = self.desired_accel;

    if(self.heliType != "flares" && isDefined(self.primaryTarget) && !self heli_is_threatened())
      goalSpeed *= 0.25;

    if(lastSpeed != goalSpeed || lastAccel != goalAccel) {
      self Vehicle_SetSpeed(goalSpeed, goalAccel);

      lastSpeed = goalSpeed;
      lastAccel = goalAccel;
    }

    wait(0.05);
  }
}


heli_is_threatened() {
  if(self.recentDamageAmount > 50)
    return true;

  if(self.currentState == "heavy smoke")
    return true;

  return false;
}


heli_fly_well(destNodes) {
  self notify("flying");
  self endon("flying");

  self endon("death");
  self endon("crashing");
  self endon("leaving");

  level endon("game_ended");

  for (;;) {
    currentNode = self get_best_area_attack_node(destNodes);

    travelToNode(currentNode);

    // motion change via node
    if(isdefined(currentNode.script_airspeed) && isdefined(currentNode.script_accel)) {
      heli_speed = currentNode.script_airspeed;
      heli_accel = currentNode.script_accel;
    } else {
      heli_speed = 30 + randomInt(20);
      heli_accel = 15 + randomInt(15);
    }

    self Vehicle_SetSpeed(heli_speed, heli_accel);
    self setvehgoalpos(currentNode.origin + self.zOffset, 1);
    self setgoalyaw(currentNode.angles[1] + level.heli_angle_offset);

    if(level.heli_forced_wait != 0) {
      self waittill("near_goal"); //self waittillmatch( "goal" );
      wait(level.heli_forced_wait);
    } else if(!isdefined(currentNode.script_delay)) {
      self waittill("near_goal"); //self waittillmatch( "goal" );

      wait(5 + randomInt(5));
    } else {
      self waittillmatch("goal");
      wait(currentNode.script_delay);
    }
  }
}


get_best_area_attack_node(destNodes) {
  return updateAreaNodes(destNodes);
}


// helicopter leaving parameter, can not be damaged while leaving
heli_leave() {
  self notify("leaving");

  leaveNode = level.heli_leave_nodes[randomInt(level.heli_leave_nodes.size)];

  self heli_reset();
  self Vehicle_SetSpeed(100, 45);
  self setvehgoalpos(leaveNode.origin, 1);
  self waittillmatch("goal");
  self notify("death");

  // give "death" notify time to process
  wait(0.05);
  self delete();
}


// ====================================================================================
// 								DEBUG INFORMATION
// ====================================================================================

debug_print3d(message, color, ent, origin_offset, frames) {
  if(isdefined(level.heli_debug) && level.heli_debug == 1.0)
    self thread draw_text(message, color, ent, origin_offset, frames);
}

debug_print3d_simple(message, ent, offset, frames) {
  if(isdefined(level.heli_debug) && level.heli_debug == 1.0) {
    if(isdefined(frames))
      thread draw_text(message, (0.8, 0.8, 0.8), ent, offset, frames);
    else
      thread draw_text(message, (0.8, 0.8, 0.8), ent, offset, 0);
  }
}

debug_line(from, to, color, frames) {
  if(isdefined(level.heli_debug) && level.heli_debug == 1.0 && !isdefined(frames)) {
    thread draw_line(from, to, color);
  } else if(isdefined(level.heli_debug) && level.heli_debug == 1.0)
    thread draw_line(from, to, color, frames);
}

draw_text(msg, color, ent, offset, frames) {
  //level endon( "helicopter_done" );
  if(frames == 0) {
    while (isdefined(ent)) {
      print3d(ent.origin + offset, msg, color, 0.5, 4);
      wait 0.05;
    }
  } else {
    for (i = 0; i < frames; i++) {
      if(!isdefined(ent))
        break;
      print3d(ent.origin + offset, msg, color, 0.5, 4);
      wait 0.05;
    }
  }
}

draw_line(from, to, color, frames) {
  //level endon( "helicopter_done" );
  if(isdefined(frames)) {
    for (i = 0; i < frames; i++) {
      line(from, to, color);
      wait 0.05;
    }
  } else {
    for (;;) {
      line(from, to, color);
      wait 0.05;
    }
  }
}



addToHeliList() {
  level.helis[self getEntityNumber()] = self;
}

removeFromHeliList(entityNumber) {
  level.helis[entityNumber] = undefined;
}


playFlareFx() {
  for (i = 0; i < 10; i++) {
    if(!isDefined(self))
      return;
    PlayFXOnTag(level._effect["h2_ac130_flare"], self, "TAG_FLARE");
    wait(0.15);
  }
}


deployFlares() {
  flareObject = spawn("script_origin", level.UAVRig.origin);
  flareObject.angles = level.UAVRig.angles;

  flareObject moveGravity((0, 0, 0), 5.0);

  flareObject thread deleteAfterTime(5.0);

  return flareObject;
}


heli_flares_monitor() {
  level endon("game_ended");
  self endon("helicopter_done");

  for (;;) {
    level waittill("stinger_fired", player, missile, lockTarget);

    if(!IsDefined(lockTarget) || (lockTarget != self))
      continue;

    missile endon("death");

    self thread playFlareFx();
    newTarget = self deployFlares();
    missile Missile_SetTargetEnt(newTarget);
    return;
  }
}

deleteAfterTime(delay) {
  wait(delay);

  if(isDefined(self))
    self delete();
}