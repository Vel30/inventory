#include <YSI_Coding\y_hooks>

static Container: gPlayerInventoryContainerID[MAX_PLAYERS];

hook OnPlayerConnect(playerid) {
  gPlayerInventoryContainerID[playerid] = CreateContainer(va_return("Inventário de %s", ReturnPlayerRPName(playerid)), 100);
}

hook OnPlayerDisconnect(playerid, reason) {
  DestroyContainer(gPlayerInventoryContainerID[playerid]);
}

hook OnPlayerKeyStateChange(playerid, KEY: newkeys, KEY: oldkeys) {
  if (newkeys & KEY_NO) {
    ShowContainerForPlayer(playerid, gPlayerInventoryContainerID[playerid]);
  }
}

Container: GetPlayerInventoryContainerID(playerid) {
  return !IsPlayerConnected(playerid) ? INVALID_CONTAINER_ID : gPlayerInventoryContainerID[playerid];
}
