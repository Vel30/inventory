#include <YSI_Coding\y_hooks>

static enum E_ITEM_TYPE_PREVIEW_ROT_DATA {
  Float: E_ITEM_TYPE_PREVIEW_ROT_X,
  Float: E_ITEM_TYPE_PREVIEW_ROT_Y,
  Float: E_ITEM_TYPE_PREVIEW_ROT_Z,
  Float: E_ITEM_TYPE_PREVIEW_ROT_ZOOM
};

static gItemTypePreviewRotData[MAX_ITEM_TYPES][E_ITEM_TYPE_PREVIEW_ROT_DATA];

forward bool: SetItemTypePreviewRot(ItemType: itemtypeid, Float: x, Float: y, Float: z, Float: zoom = 1.5);
forward bool: GetItemTypePreviewRot(ItemType: itemtypeid, &Float: x, &Float: y, &Float: z, &Float: zoom);

hook OnScriptInit() {
  for (new i; i < MAX_ITEM_TYPES; i++) {
    gItemTypePreviewRotData[i][E_ITEM_TYPE_PREVIEW_ROT_X] = 0.0;
    gItemTypePreviewRotData[i][E_ITEM_TYPE_PREVIEW_ROT_Y] = 0.0;
    gItemTypePreviewRotData[i][E_ITEM_TYPE_PREVIEW_ROT_Z] = 0.0;
    gItemTypePreviewRotData[i][E_ITEM_TYPE_PREVIEW_ROT_ZOOM] = 1.5;
  }
}

bool: SetItemTypePreviewRot(ItemType: itemtypeid, Float: x, Float: y, Float: z, Float: zoom = 1.5) {
  if (!IsValidItemType(itemtypeid)) {
    return false;
  }

  gItemTypePreviewRotData[_: itemtypeid][E_ITEM_TYPE_PREVIEW_ROT_X] = x;
  gItemTypePreviewRotData[_: itemtypeid][E_ITEM_TYPE_PREVIEW_ROT_Y] = y;
  gItemTypePreviewRotData[_: itemtypeid][E_ITEM_TYPE_PREVIEW_ROT_Z] = z;
  gItemTypePreviewRotData[_: itemtypeid][E_ITEM_TYPE_PREVIEW_ROT_ZOOM] = zoom;
  return true;
}

bool: GetItemTypePreviewRot(ItemType: itemtypeid, &Float: x, &Float: y, &Float: z, &Float: zoom) {
  if (!IsValidItemType(itemtypeid)) {
    return false;
  }

  x = gItemTypePreviewRotData[_: itemtypeid][E_ITEM_TYPE_PREVIEW_ROT_X];
  y = gItemTypePreviewRotData[_: itemtypeid][E_ITEM_TYPE_PREVIEW_ROT_Y];
  z = gItemTypePreviewRotData[_: itemtypeid][E_ITEM_TYPE_PREVIEW_ROT_Z];
  zoom = gItemTypePreviewRotData[_: itemtypeid][E_ITEM_TYPE_PREVIEW_ROT_ZOOM];
  return true;
}
