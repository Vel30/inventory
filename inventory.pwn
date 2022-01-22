#include <a_samp>
#include <Pawn.CMD> // https://github.com/katursis/Pawn.CMD
#include <sscanf2> // https://github.com/maddinat0r/sscanf

#define MAX_ITEMS (16)
#define MAX_PLAYER_ITEMS (10)
#define MAX_ITEM_NAME (32)
#define MAX_ITEM_DESCRIPTION (128)

const Item: INVALID_ITEM_ID = Item: -1;
// const MAX_ITEM_NAME = 32;
// const MAX_ITEM_DESCRIPTION = 128;

enum E_ITEM_DATA {
  E_ITEM_DATA_MODEL,
  E_ITEM_DATA_NAME[MAX_ITEM_NAME + 1 char],
  E_ITEM_DATA_COLOR,
  E_ITEM_DATA_MAX_STACK,
  E_ITEM_DATA_DESCRIPTION[MAX_ITEM_DESCRIPTION + 1 char]
};

static gItemData[MAX_ITEMS][E_ITEM_DATA];

new gItemPoolSize;

enum E_PLAYER_ITEM_DATA {
  Item: E_PLAYER_ITEM_DATA_ITEM_ID,
  E_PLAYER_ITEM_DATA_ITEM_AMOUNT
};

static gPlayerItemData[MAX_PLAYERS][MAX_PLAYER_ITEMS][E_PLAYER_ITEM_DATA],
  gPlayerSelectedItemSlot[MAX_PLAYERS] = { -1, ... };

forward Item: Item_Define(model, const name[], color = -1, maxStack = cellmax, const description[] = "");
forward bool: Item_IsValid(Item: item);
forward bool: Item_IsStackable(Item: item);

forward OnPlayerUseItem(playerid, Item: item);

stock Item: gBurger = INVALID_ITEM_ID,
  Item: gSoda = INVALID_ITEM_ID;

public OnFilterScriptInit() {
  gBurger = Item_Define(2880, "Hambúrguer", 0xF39C62FF, 5);
  gSoda = Item_Define(2601, "Refrigerante", 0xEE593EFF, 1);
}

public OnPlayerConnect(playerid) {
  PlayerItems_Clear(playerid);

  gPlayerSelectedItemSlot[playerid] = -1;

  PlayerItems_Load(playerid);
  return 1;
}

public OnPlayerDisconnect(playerid, reason) {
  PlayerItems_Save(playerid);
  return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) {
  switch (dialogid) {
    case 4510: {
      if (!response) {
        return 1;
      }

      new Item: item = gPlayerItemData[playerid][listitem][E_PLAYER_ITEM_DATA_ITEM_ID];

      if (!Item_IsValid(item)) {
        PlayerItems_Show(playerid);
        return 1;
      }

      gPlayerSelectedItemSlot[playerid] = listitem;

      ShowPlayerDialog(playerid, 4511, DIALOG_STYLE_LIST, Item_GetName(item), "Usar\nVer detalhes", "Selecionar", "Voltar");
      return 1;
    }
    case 4511: {
      if (!response) {
        gPlayerSelectedItemSlot[playerid] = -1;

        PlayerItems_Show(playerid);
        return 1;
      }

      new slot = gPlayerSelectedItemSlot[playerid];

      if (slot == -1) {
        PlayerItems_Show(playerid);
        return 1;
      }

      switch (listitem) {
        case 0: {
          if (!PlayerItem_Use(playerid, slot)) {
            PlayerItems_Show(playerid);
          } else {
            // 
          }

          gPlayerSelectedItemSlot[playerid] = -1;
          return 1;
        }
        case 1: {
          return 1;
        }
      }
      return 1;
    }
  }
  return 0;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys) {
  if (newkeys & KEY_YES) {
    PlayerItems_Show(playerid);
  }
}

public OnPlayerUseItem(playerid, Item: item) {
  new str[(MAX_ITEM_NAME + 1) + 8];

  format(str, sizeof(str), "{%06x}%s{FFFFFF} usado.", Item_GetColor(item) >>> 8, Item_GetName(item));
  SendClientMessage(playerid, -1, str);
  return 1;
}

Item: Item_Define(model, const name[], color = -1, maxStack = cellmax, const description[] = "") {
  if (gItemPoolSize == MAX_ITEMS) {
    return INVALID_ITEM_ID;
  }

  gItemData[gItemPoolSize][E_ITEM_DATA_MODEL] = model;
  strpack(gItemData[gItemPoolSize][E_ITEM_DATA_NAME], name, MAX_ITEM_NAME + 1 char);
  gItemData[gItemPoolSize][E_ITEM_DATA_COLOR] = color;
  gItemData[gItemPoolSize][E_ITEM_DATA_MAX_STACK] = maxStack;
  strpack(gItemData[gItemPoolSize][E_ITEM_DATA_DESCRIPTION], description, MAX_ITEM_DESCRIPTION + 1 char);
  return Item: gItemPoolSize++;
}

bool: Item_IsValid(Item: item) {
  return 0 <= _: item < gItemPoolSize;
}

Item_GetName(Item: item) {
  new name[MAX_ITEM_NAME + 1];

  if (Item_IsValid(item)) {
    strunpack(name, gItemData[_: item][E_ITEM_DATA_NAME]);
  }
  return name;
}

Item_GetColor(Item: item) {
  return !Item_IsValid(item) ? -1 : gItemData[_: item][E_ITEM_DATA_COLOR];
}

Item_GetDescription(Item: item) {
  new description[MAX_ITEM_DESCRIPTION + 1];

  if (Item_IsValid(item)) {
    strunpack(description, gItemData[_: item][E_ITEM_DATA_DESCRIPTION]);
  }
  return description;
}

bool: Item_IsStackable(Item: item) {
  return Item_IsValid(item) && !!gItemData[_: item][E_ITEM_DATA_MAX_STACK];
}

PlayerItem_Add(playerid, Item: item, amount = 1, slot = -1) {
  if (!IsPlayerConnected(playerid)) {
    return 0;
  }

  if (!Item_IsValid(item)) {
    return -1;
  }

  if (!amount) {
    return -2;
  }

  if (amount < 0) {
    PlayerItem_Remove(playerid, slot, (amount = -amount));
    return -3;
  }

  if (slot != -1) {
    if (!(0 <= slot < MAX_PLAYER_ITEMS)) {
      return -4;
    }
  }

  if (slot == -1) {
    for (new i; i < MAX_PLAYER_ITEMS; i++) {
      if (gPlayerItemData[playerid][i][E_PLAYER_ITEM_DATA_ITEM_ID] == item && gPlayerItemData[playerid][i][E_PLAYER_ITEM_DATA_ITEM_AMOUNT] < gItemData[_: item][E_ITEM_DATA_MAX_STACK]) {
        slot = i;
        break;
      }
    }

    if (slot == -1) {
      for (new i; i < MAX_PLAYER_ITEMS; i++) {
        if (gPlayerItemData[playerid][i][E_PLAYER_ITEM_DATA_ITEM_ID] == INVALID_ITEM_ID) {
          slot = i;
          break;
        }
      }

      if (slot == -1) {
        return -5;
      }
    }
  }

  if (gPlayerItemData[playerid][slot][E_PLAYER_ITEM_DATA_ITEM_AMOUNT] + amount > gItemData[_: item][E_ITEM_DATA_MAX_STACK]) {
    amount -= gItemData[_: item][E_ITEM_DATA_MAX_STACK] - gPlayerItemData[playerid][slot][E_PLAYER_ITEM_DATA_ITEM_AMOUNT];

    gPlayerItemData[playerid][slot][E_PLAYER_ITEM_DATA_ITEM_ID] = item;
    gPlayerItemData[playerid][slot][E_PLAYER_ITEM_DATA_ITEM_AMOUNT] = gItemData[_: item][E_ITEM_DATA_MAX_STACK];

    if (amount) {
      PlayerItem_Add(playerid, item, amount);
    }
  } else {
    gPlayerItemData[playerid][slot][E_PLAYER_ITEM_DATA_ITEM_ID] = item;
    gPlayerItemData[playerid][slot][E_PLAYER_ITEM_DATA_ITEM_AMOUNT] += amount;
  }
  return 1;
}

PlayerItem_Remove(playerid, slot, amount = cellmax) {
  if (!IsPlayerConnected(playerid)) {
    return 0;
  }

  if (!(0 <= slot < MAX_PLAYER_ITEMS)) {
    return -1;
  }

  if (gPlayerItemData[playerid][slot][E_PLAYER_ITEM_DATA_ITEM_ID] == INVALID_ITEM_ID) {
    return -2;
  }

  if (!(gPlayerItemData[playerid][slot][E_PLAYER_ITEM_DATA_ITEM_AMOUNT] = clamp((gPlayerItemData[playerid][slot][E_PLAYER_ITEM_DATA_ITEM_AMOUNT] -= amount), 0))) {
    gPlayerItemData[playerid][slot][E_PLAYER_ITEM_DATA_ITEM_ID] = INVALID_ITEM_ID;
  }
  return 1;
}

PlayerItems_Clear(playerid, &count = 0) {
  if (!IsPlayerConnected(playerid)) {
    return 0;
  }

  for (new i; i < MAX_PLAYER_ITEMS; i++) {
    if (gPlayerItemData[playerid][i][E_PLAYER_ITEM_DATA_ITEM_ID] != INVALID_ITEM_ID) {
      count += gPlayerItemData[playerid][i][E_PLAYER_ITEM_DATA_ITEM_AMOUNT];

      gPlayerItemData[playerid][i][E_PLAYER_ITEM_DATA_ITEM_ID] = INVALID_ITEM_ID;
      gPlayerItemData[playerid][i][E_PLAYER_ITEM_DATA_ITEM_AMOUNT] = 0;
    }
  }

  if (!count) {
    return -1;
  }
  return 1;
}

PlayerItem_Use(playerid, slot) {
  new Item: item = gPlayerItemData[playerid][slot][E_PLAYER_ITEM_DATA_ITEM_ID];

  if (!Item_IsValid(item)) {
    return 0;
  }

  if (PlayerItem_Remove(playerid, slot, 1)) {
    if (!OnPlayerUseItem(playerid, item)) {
      return -1;
    }
  }
  return 1;
}

PlayerItems_Show(playerid) {
  if (!IsPlayerConnected(playerid)) {
    return 0;
  }

  new list[(MAX_ITEM_NAME + 1) * MAX_PLAYER_ITEMS] = "# Item\tQuantidade";

  for (new i; i < MAX_PLAYER_ITEMS; i++) {
    format(list, sizeof(list), "%s\n%02d {%06x}%s\t%d", list, i + 1, Item_GetColor(gPlayerItemData[playerid][i][E_PLAYER_ITEM_DATA_ITEM_ID]) >>> 8, gPlayerItemData[playerid][i][E_PLAYER_ITEM_DATA_ITEM_ID] != INVALID_ITEM_ID ? Item_GetName(gPlayerItemData[playerid][i][E_PLAYER_ITEM_DATA_ITEM_ID]) : "--", gPlayerItemData[playerid][i][E_PLAYER_ITEM_DATA_ITEM_ID] != INVALID_ITEM_ID ? gPlayerItemData[playerid][i][E_PLAYER_ITEM_DATA_ITEM_AMOUNT] : cellmax + 1);
  }

  ShowPlayerDialog(playerid, 4510, DIALOG_STYLE_TABLIST_HEADERS, "Seu Inventário", list, "Usar", "Fechar");
  return 1;
}

PlayerItems_Save(playerid) {
  new path[(MAX_PLAYER_NAME + 1) + 5], 
    name[MAX_PLAYER_NAME + 1];

  GetPlayerName(playerid, name, MAX_PLAYER_NAME + 1);

  format(path, sizeof(path), "%s.ini", name);

  new File: file = fopen(path, io_write);

  if (file) {
    new buffer[32];

    for (new i; i < MAX_PLAYER_ITEMS; i++) {
      format(buffer, sizeof(buffer), "%d, %d\r\n", _: gPlayerItemData[playerid][i][E_PLAYER_ITEM_DATA_ITEM_ID], gPlayerItemData[playerid][i][E_PLAYER_ITEM_DATA_ITEM_AMOUNT]);

      fwrite(file, buffer);
    }

    fclose(file);
  }
}

PlayerItems_Load(playerid, &count = 0) {
  new path[(MAX_PLAYER_NAME + 1) + 5], 
    name[MAX_PLAYER_NAME + 1];

  GetPlayerName(playerid, name, MAX_PLAYER_NAME + 1);

  format(path, sizeof(path), "%s.ini", name);

  new File: file = fopen(path);

  if (file) {
    new buffer[32 * (MAX_PLAYER_ITEMS + 1)];

    while (fread(file, buffer)) {
      sscanf(buffer, "p<,>e<dd>", gPlayerItemData[playerid][count++]);
    }

    fclose(file);
  }
}

CMD:daritem(playerid, params[]) {
  if (!IsPlayerAdmin(playerid)) {
    SendClientMessage(playerid, -1, "Você não tem permissão para fazer isso!");
    return 1;
  }

  new player, 
    Item: item, 
    amount,
    slot;

  if (sscanf(params, "rdD(1)D(-1)", player, _: item, amount, slot)) {
    SendClientMessage(playerid, -1, "/daritem [jogador] [item] [(opcional) quantidade] [(opcional) slot]");
    return 1;
  }

  switch (PlayerItem_Add(player, item, amount, slot)) {
    case 0: {
      SendClientMessage(playerid, -1, "Jogador desconectado.");
    }
    case -1: {
      SendClientMessage(playerid, -1, "Item inválido.");
    }
    case -2, -3: {
      SendClientMessage(playerid, -1, "Nenhum item foi adicionado.");
    }
    case -4: {
      SendClientMessage(playerid, -1, "Slot inválido.");
    }
    case -5: {
      SendClientMessage(playerid, -1, "O inventário do jogador está cheio.");
    }
    case 1: {
      SendClientMessage(playerid, -1, "Item adicionado com sucesso!");
    }
  }
  return 1;
}

CMD:removeritem(playerid, params[]) {
  if (!IsPlayerAdmin(playerid)) {
    SendClientMessage(playerid, -1, "Você não tem permissão para fazer isso!");
    return 1;
  }

  new player, 
    slot, 
    amount;

  if (sscanf(params, "rdD(-1)", player, slot, amount)) {
    SendClientMessage(playerid, -1, "/removeritem [jogador] [slot] [(opcional) quantidade]");
    return 1;
  }

  switch (PlayerItem_Remove(player, slot, amount != -1 ? amount : cellmax)) {
    case 0: {
      SendClientMessage(playerid, -1, "Jogador desconectado.");
    }
    case -1: {
      SendClientMessage(playerid, -1, "Slot inválido.");
    }
    case -2: {
      SendClientMessage(playerid, -1, "O inventário do jogador não tem um item válido neste slot.");
    }
    case 1: {
      SendClientMessage(playerid, -1, "Item removido com sucesso!");
    }
  }
  return 1;
}

CMD:limparinv(playerid, params[]) {
  if (!IsPlayerAdmin(playerid)) {
    SendClientMessage(playerid, -1, "Você não tem permissão para fazer isso!");
    return 1;
  }

  new player;

  if (sscanf(params, "r", player)) {
    SendClientMessage(playerid, -1, "/limparinv [jogador]");
    return 1;
  }

  new count;

  switch (PlayerItems_Clear(player, count)) {
    case 0: {
      SendClientMessage(playerid, -1, "Jogador desconectado.");
    }
    case -1: {
      SendClientMessage(playerid, -1, "O inventário do jogador já está vazio.");
    }
    case 1: {
      new str[32];

      format(str, sizeof(str), "%d itens foram excluídos.", count);
      SendClientMessage(playerid, -1, str);
    }
  }
  return 1;
}
