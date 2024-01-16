#define MAX_CONTAINERS 2048
#define MAX_CONTAINER_NAME 48
#define MAX_CONTAINER_SIZE 512
#define MAX_CONTAINER_ITEM_EXTRA_DATA 256
#define MAX_CONTAINER_ITEMS_PER_PAGE 8

const Container: INVALID_CONTAINER_ID = Container: cellmin;

static enum E_CONTAINER_DATA {
  string: E_CONTAINER_NAME[MAX_CONTAINER_NAME char],
  E_CONTAINER_SIZE
};

static enum E_CONTAINER_ITEM_DATA {
  ItemType: E_CONTAINER_ITEM_TYPE_ID,
  E_CONTAINER_ITEM_STACK_SIZE,
  string: E_CONTAINER_ITEM_NAME[MAX_ITEM_TYPE_NAME char],
  E_CONTAINER_ITEM_EXTRA_DATA[MAX_CONTAINER_ITEM_EXTRA_DATA],
  E_CONTAINER_ITEM_EXTRA_DATA_SIZE
};

static gContainerData[MAX_CONTAINERS][E_CONTAINER_DATA],
  gContainerItemData[MAX_CONTAINERS][MAX_CONTAINER_SIZE][E_CONTAINER_ITEM_DATA],
  gItemTypeExtraDataMaxSize[MAX_ITEM_TYPES];

new Iterator: Container<MAX_CONTAINERS>;

forward OnContainerItemAdded(Container: containerid, slotid);
forward OnContainerItemRemoved(Container: containerid, slotid);
forward OnPlayerUseContainerItem(playerid, Container: containerid, slotid);

#define ALS_DO_ContainerItemAdded<%0> %0<ContainerItemAdded, dd>(Container: containerid, slotid)
#define ALS_DO_ContainerItemRemoved<%0> %0<ContainerItemRemoved, dd>(Container: containerid, slotid)
#define ALS_DO_PlayerUseContainerItem<%0> %0<PlayerUseContainerItem, ddd>(playerid, Container: containerid, slotid)

forward Container: CreateContainer(const string: name[], size);
forward bool: DestroyContainer(Container: containerid);
forward bool: IsValidContainer(Container: containerid);
forward AddItemToContainer(Container: containerid, ItemType: itemtypeid, amount = 1, slotid = cellmin, const data[] = { cellmin }, size = sizeof(data));
forward RemoveItemFromContainer(Container: containerid, slotid, amount = cellmax);
forward bool: SetContainerName(Container: containerid, const string: name[]);
forward bool: SetContainerSize(Container: containerid, size);
forward SetContainerItemName(Container: containerid, slotid, const string: name[]);
forward SetContainerItemExtraData(Container: containerid, slotid, const data[], size = sizeof(data));
forward SetContainerItemExtraDataAtCell(Container: containerid, slotid, cellid, data);
forward SetContainerItemExtraDataSize(Container: containerid, slotid, size);
forward SetItemTypeExtraDataMaxSize(ItemType: itemtypeid, size);
forward string: GetContainerName(Container: containerid);
forward GetContainerSize(Container: containerid);
forward ItemType: GetContainerItemTypeID(Container: containerid, slotid);
forward GetContainerItemStackSize(Container: containerid, slotid);
forward string: GetContainerItemName(Container: containerid, slotid);
forward GetContainerItemExtraData(Container: containerid, slotid, data[]);
forward GetContainerItemExtraDataAtCell(Container: containerid, slotid, cellid);
forward GetContainerItemExtraDataSize(Container: containerid, slotid);
forward GetItemTypeExtraDataMaxSize(ItemType: itemtypeid);
forward UseContainerItemForPlayer(playerid, Container: containerid, slotid);
forward ShowContainerForPlayer(playerid, Container: containerid, page = 1);

Container: CreateContainer(const string: name[], size) {
  new containerid = Iter_Free(Container);

  if (containerid == ITER_NONE) {
    return INVALID_CONTAINER_ID;
  }

  strpack(gContainerData[containerid][E_CONTAINER_NAME], name);
  gContainerData[containerid][E_CONTAINER_SIZE] = size;

  for (new i; i < size; i++) {
    gContainerItemData[containerid][i][E_CONTAINER_ITEM_TYPE_ID] = INVALID_ITEM_TYPE_ID;
    gContainerItemData[containerid][i][E_CONTAINER_ITEM_STACK_SIZE] = 0;
  }

  Iter_Add(Container, containerid);
  return Container: containerid;
}

bool: DestroyContainer(Container: containerid) {
  if (!IsValidContainer(containerid)) {
    return false;
  }

  Iter_Remove(Container, _: containerid);
  return true;
}

bool: IsValidContainer(Container: containerid) {
  return Iter_Contains(Container, _: containerid);
}

AddItemToContainer(Container: containerid, ItemType: itemtypeid, amount = 1, slotid = cellmin, const data[] = { cellmin }, size = sizeof(data)) {
  if (!IsValidContainer(containerid)) {
    return 0;
  }

  if (!IsValidItemType(itemtypeid)) {
    return -1;
  }

  if (!amount) {
    return -2;
  }

  if (amount < 0) {
    RemoveItemFromContainer(containerid, slotid, amount * -1);
    return -3;
  }

  if (slotid != cellmin) {
    if (!UCMP(slotid, gContainerData[_: containerid][E_CONTAINER_SIZE])) {
      return -4;
    }
  }

  new maxStackSize = GetItemTypeMaxStackSize(itemtypeid);

  if (slotid == cellmin) {
    for (new i; i < gContainerData[_: containerid][E_CONTAINER_SIZE]; i++) {
      if (gContainerItemData[_: containerid][i][E_CONTAINER_ITEM_TYPE_ID] == itemtypeid && gContainerItemData[_: containerid][i][E_CONTAINER_ITEM_STACK_SIZE] < maxStackSize) {
        new extraData[MAX_CONTAINER_ITEM_EXTRA_DATA],
          extraDataSize = GetContainerItemExtraData(containerid, i, extraData);

        if (IsEqual1DArray(extraData, data, extraDataSize, size)) {
          slotid = i;
          break;
        }
      }
    }

    if (slotid == cellmin) {
      for (new i; i < gContainerData[_: containerid][E_CONTAINER_SIZE]; i++) {
        if (gContainerItemData[_: containerid][i][E_CONTAINER_ITEM_TYPE_ID] == INVALID_ITEM_TYPE_ID) {
          slotid = i;
          break;
        }
      }

      if (slotid == cellmin) {
        return -5;
      }
    }
  }

  gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_TYPE_ID] = itemtypeid;

  if (gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_STACK_SIZE] + amount <= maxStackSize) {
    gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_STACK_SIZE] += amount;
  } else {
    amount -= maxStackSize - gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_STACK_SIZE];

    gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_STACK_SIZE] = maxStackSize;

    if (amount) {
      AddItemToContainer(containerid, itemtypeid, amount, .data = data, .size = size);
    }
  }

  SetContainerItemExtraData(containerid, slotid, data, size);

  call OnContainerItemAdded(_: containerid, slotid);
  return 1;
}

RemoveItemFromContainer(Container: containerid, slotid, amount = cellmax) {
  if (!IsValidContainer(containerid)) {
    return 0;
  }

  if (!UCMP(slotid, gContainerData[_: containerid][E_CONTAINER_SIZE])) {
    return -1;
  }

  if (gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_TYPE_ID] == INVALID_ITEM_TYPE_ID) {
    return -2;
  }

  if (!(gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_STACK_SIZE] = clamp((gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_STACK_SIZE] -= amount), 0))) {
    gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_TYPE_ID] = INVALID_ITEM_TYPE_ID;
  }

  call OnContainerItemRemoved(_: containerid, slotid);
  return 1;
}

bool: SetContainerName(Container: containerid, const string: name[]) {
  if (!IsValidContainer(containerid)) {
    return false;
  }

  strpack(gContainerData[_: containerid][E_CONTAINER_NAME], name);
  return true;
}

bool: SetContainerSize(Container: containerid, size) {
  if (!IsValidContainer(containerid)) {
    return false;
  }

  gContainerData[_: containerid][E_CONTAINER_SIZE] = size;
  return true;
}

SetContainerItemName(Container: containerid, slotid, const string: name[]) {
  if (!IsValidContainer(containerid)) {
    return 0;
  }

  if (!UCMP(slotid, gContainerData[_: containerid][E_CONTAINER_SIZE])) {
    return -1;
  }

  strpack(gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_NAME], name);
  return 1;
}

SetContainerItemExtraData(Container: containerid, slotid, const data[], size = sizeof(data)) {
  if (!IsValidContainer(containerid)) {
    return 0;
  }

  if (!UCMP(slotid, gContainerData[_: containerid][E_CONTAINER_SIZE])) {
    return -1;
  }

  new ItemType: itemtypeid = gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_TYPE_ID];

  if (itemtypeid == INVALID_ITEM_TYPE_ID) {
    return -2;
  }

  if (size > gItemTypeExtraDataMaxSize[_: itemtypeid]) {
    return -3;
  }

  gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_EXTRA_DATA_SIZE] = 0;

  for (new i; i < size; i++) {
    gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_EXTRA_DATA][gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_EXTRA_DATA_SIZE]++] = data[i];
  }
  return 1;
}

SetContainerItemExtraDataAtCell(Container: containerid, slotid, cellid, data) {
  if (!IsValidContainer(containerid)) {
    return 0;
  }

  if (!UCMP(slotid, gContainerData[_: containerid][E_CONTAINER_SIZE])) {
    return -1;
  }

  new ItemType: itemtypeid = gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_TYPE_ID];

  if (itemtypeid == INVALID_ITEM_TYPE_ID) {
    return -2;
  }

  if (!UCMP(cellid, gItemTypeExtraDataMaxSize[_: itemtypeid])) {
    return -3;
  }

  gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_EXTRA_DATA][cellid] = data;
  return 1;
}

SetContainerItemExtraDataSize(Container: containerid, slotid, size) {
  if (!IsValidContainer(containerid)) {
    return 0;
  }

  if (!UCMP(slotid, gContainerData[_: containerid][E_CONTAINER_SIZE])) {
    return -1;
  }

  new ItemType: itemtypeid = gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_TYPE_ID];

  if (itemtypeid == INVALID_ITEM_TYPE_ID) {
    return -2;
  }

  if (size > gItemTypeExtraDataMaxSize[_: itemtypeid]) {
    return -3;
  }

  gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_EXTRA_DATA_SIZE] = size;
  return 1;
}

SetItemTypeExtraDataMaxSize(ItemType: itemtypeid, size) {
  if (!IsValidItemType(itemtypeid)) {
    return 0;
  }

  if (size > MAX_CONTAINER_ITEM_EXTRA_DATA) {
    return -1;
  }

  gItemTypeExtraDataMaxSize[_: itemtypeid] = size;
  return 1;
}

string: GetContainerName(Container: containerid) {
  new string: name[MAX_CONTAINER_NAME + 1];

  if (IsValidContainer(containerid)) {
    strunpack(name, gContainerData[_: containerid][E_CONTAINER_NAME]);
  }
  return name;
}

GetContainerSize(Container: containerid) {
  return !IsValidContainer(containerid) ? 0 : gContainerData[_: containerid][E_CONTAINER_SIZE];
}

ItemType: GetContainerItemTypeID(Container: containerid, slotid) {
  return IsValidContainer(containerid) && UCMP(slotid, gContainerData[_: containerid][E_CONTAINER_SIZE]) ? (gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_TYPE_ID]) : INVALID_ITEM_TYPE_ID;
}

GetContainerItemStackSize(Container: containerid, slotid) {
  return IsValidContainer(containerid) && UCMP(slotid, gContainerData[_: containerid][E_CONTAINER_SIZE]) ? (gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_STACK_SIZE]) : 0;
}

string: GetContainerItemName(Container: containerid, slotid) {
  new string: name[MAX_ITEM_TYPE_NAME + 1];

  if (IsValidContainer(containerid) && UCMP(slotid, gContainerData[_: containerid][E_CONTAINER_SIZE])) {
    strunpack(name, gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_NAME]);
  }
  return name;
}

GetContainerItemExtraData(Container: containerid, slotid, data[]) {
  if (!IsValidContainer(containerid)) {
    return 0;
  }

  if (!UCMP(slotid, gContainerData[_: containerid][E_CONTAINER_SIZE])) {
    return -1;
  }

  for (new i; i < gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_EXTRA_DATA_SIZE]; i++) {
    data[i] = gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_EXTRA_DATA][i];
  }
  return gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_EXTRA_DATA_SIZE];
}

GetContainerItemExtraDataAtCell(Container: containerid, slotid, cellid) {
  return IsValidContainer(containerid) && UCMP(slotid, gContainerData[_: containerid][E_CONTAINER_SIZE]) && gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_TYPE_ID] != INVALID_ITEM_TYPE_ID && UCMP(cellid, gItemTypeExtraDataMaxSize[_: gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_TYPE_ID]]) ? (gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_EXTRA_DATA][cellid]) : 0;
}

GetContainerItemExtraDataSize(Container: containerid, slotid) {
  return IsValidContainer(containerid) && UCMP(slotid, gContainerData[_: containerid][E_CONTAINER_SIZE]) ? gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_EXTRA_DATA_SIZE] : 0;
}

GetItemTypeExtraDataMaxSize(ItemType: itemtypeid) {
  return !IsValidItemType(itemtypeid) ? 0 : gItemTypeExtraDataMaxSize[_: itemtypeid];
}

UseContainerItemForPlayer(playerid, Container: containerid, slotid) {
  if (!IsPlayerConnected(playerid)) {
    return 0;
  }

  if (!IsValidContainer(containerid)) {
    return -1;
  }

  if (!UCMP(slotid, gContainerData[_: containerid][E_CONTAINER_SIZE])) {
    return -2;
  }

  if (gContainerItemData[_: containerid][slotid][E_CONTAINER_ITEM_TYPE_ID] == INVALID_ITEM_TYPE_ID) {
    return -3;
  }

  if (!call OnPlayerUseContainerItem(playerid, _: containerid, slotid)) {
    return -4;
  }

  RemoveItemFromContainer(containerid, slotid, 1);
  return 1;
}

ShowContainerForPlayer(playerid, Container: containerid, page = 1) {
  if (!IsPlayerConnected(playerid)) {
    return 0;
  }

  if (!IsValidContainer(containerid)) {
    return -1;
  }

  new string: list[(MAX_ITEM_TYPE_NAME + 1) * MAX_CONTAINER_SIZE] = "Nome\tun.",
    string: name[MAX_ITEM_TYPE_NAME + 1],
    listedItems[MAX_CONTAINER_SIZE],
    listedItemsCount;

  format(list, sizeof(list), "%s\n%s", list, page == 1 ? "Primeira página" : va_return("< Página %d", page - 1));

  for (new i = page * MAX_CONTAINER_ITEMS_PER_PAGE - MAX_CONTAINER_ITEMS_PER_PAGE; i < gContainerData[_: containerid][E_CONTAINER_SIZE]; i++) {
    if (gContainerItemData[_: containerid][i][E_CONTAINER_ITEM_TYPE_ID] == INVALID_ITEM_TYPE_ID) {
      continue;
    }

    if (listedItemsCount < MAX_CONTAINER_ITEMS_PER_PAGE) {
      format(name, sizeof(name), GetContainerItemName(containerid, i));

      if (IsNull(name)) {
        format(name, sizeof(name), GetItemTypeName(gContainerItemData[_: containerid][i][E_CONTAINER_ITEM_TYPE_ID]));
      }

      format(list, sizeof(list), "%s\n%s\t%d", list, name, gContainerItemData[_: containerid][i][E_CONTAINER_ITEM_STACK_SIZE]);
    } else {
      format(list, sizeof(list), "%s\nPágina %d >", list, page + 1);
      break;
    }

    listedItems[listedItemsCount++] = i;
  }

  inline const __(response, listitem, string: inputtext[]) {
    #pragma unused inputtext

    if (!response) {
      return 1;
    }

    if (listitem == 0) {
      ShowContainerForPlayer(playerid, containerid, page == 1 ? 1 : --page);
      return 1;
    }

    if (listitem == MAX_CONTAINER_ITEMS_PER_PAGE + 1) {
      ShowContainerForPlayer(playerid, containerid, ++page);
      return 1;
    }

    UseContainerItemForPlayer(playerid, containerid, listedItems[listitem - 1]);
  }

  Dialog_ShowCallback(playerid, using inline __, DIALOG_STYLE_TABLIST_HEADERS, GetContainerName(containerid), list, "Usar", "Fechar");
  return 1;
}
