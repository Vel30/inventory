#define MAX_ITEM_TYPES 64
#define MAX_ITEM_TYPE_NAME 48

const ItemType: INVALID_ITEM_TYPE_ID = ItemType: cellmin;

static enum E_ITEM_TYPE_DATA {
  string: E_ITEM_TYPE_NAME[MAX_ITEM_TYPE_NAME char],
  E_ITEM_TYPE_MODEL_ID,
  E_ITEM_TYPE_MAX_STACK_SIZE
};

static gItemTypeData[MAX_ITEM_TYPES][E_ITEM_TYPE_DATA],
  gItemTypePoolSize;

forward ItemType: DefineItemType(const string: name[], modelid, maxStackSize = cellmax);
forward bool: IsValidItemType(ItemType: itemtypeid);
forward GetItemTypePoolSize();
forward string: GetItemTypeName(ItemType: itemtypeid);
forward GetItemTypeModelID(ItemType: itemtypeid);
forward GetItemTypeMaxStackSize(ItemType: itemtypeid);

ItemType: DefineItemType(const string: name[], modelid, maxStackSize = cellmax) {
  if (gItemTypePoolSize == MAX_ITEM_TYPES) {
    return INVALID_ITEM_TYPE_ID;
  }

  new itemtypeid = gItemTypePoolSize;

  strpack(gItemTypeData[itemtypeid][E_ITEM_TYPE_NAME], name);
  gItemTypeData[itemtypeid][E_ITEM_TYPE_MODEL_ID] = modelid;
  gItemTypeData[itemtypeid][E_ITEM_TYPE_MAX_STACK_SIZE] = maxStackSize;
  return ItemType: gItemTypePoolSize++;
}

bool: IsValidItemType(ItemType: itemtypeid) {
  return UCMP(_: itemtypeid, gItemTypePoolSize);
}

GetItemTypePoolSize() {
  return gItemTypePoolSize;
}

string: GetItemTypeName(ItemType: itemtypeid) {
  new string: name[MAX_ITEM_TYPE_NAME + 1];

  if (IsValidItemType(itemtypeid)) {
    strunpack(name, gItemTypeData[_: itemtypeid][E_ITEM_TYPE_NAME]);
  }
  return name;
}

GetItemTypeModelID(ItemType: itemtypeid) {
  return !IsValidItemType(itemtypeid) ? 0 : gItemTypeData[_: itemtypeid][E_ITEM_TYPE_MODEL_ID];
}

GetItemTypeMaxStackSize(ItemType: itemtypeid) {
  return !IsValidItemType(itemtypeid) ? 0 : gItemTypeData[_: itemtypeid][E_ITEM_TYPE_MAX_STACK_SIZE];
}
