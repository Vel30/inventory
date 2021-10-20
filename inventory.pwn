#include <a_samp>
#include <Pawn.CMD> // https://github.com/katursis/Pawn.CMD
#include <sscanf2> // https://github.com/maddinat0r/sscanf

#define MAX_ITEMS 16
#define MAX_PLAYER_ITEMS 10

const Item: INVALID_ITEM = Item: -1;
const MAX_ITEM_NAME = 32;

enum E_ITEMS {
  ITEM_MODEL,
  ITEM_NAME[MAX_ITEM_NAME + 1 char],
  ITEM_COLOR,
  ITEM_MAX_STACK
};

static Items[MAX_ITEMS][E_ITEMS];

new ItemPoolSize;

enum E_PLAYER_ITEMS {
  Item: ITEM,
  ITEM_AMOUNT
};

static PlayerItems[MAX_PLAYERS][MAX_PLAYER_ITEMS][E_PLAYER_ITEMS];

forward Item: DefineItem(model, const name[], color = -1, max_stack = cellmax);
forward bool: IsValidItem(Item: item);

forward OnPlayerUseItem(playerid, Item: item);

stock Item: Burger = INVALID_ITEM,
  Item: Soda = INVALID_ITEM;

public OnFilterScriptInit() {
  Burger = DefineItem(2880, "Hambúrguer", 0xF39C62FF, 5);
  Soda = DefineItem(2601, "Refrigerante", 0xEE593EFF, 1);
}

public OnPlayerConnect(playerid) {
  ClearItems(playerid);

  LoadItems(playerid);
  return 1;
}

public OnPlayerDisconnect(playerid, reason) {
  SaveItems(playerid);
  return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) {
  if (dialogid == 4510 && response) {
    if (!UseItem(playerid, listitem)) {
      ShowPlayerItems(playerid);
    }
    return 1;
  }
  return 0;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys) {
  if (newkeys & KEY_YES) {
    ShowPlayerItems(playerid);
  }
}

public OnPlayerUseItem(playerid, Item: item) {
  new str[(MAX_ITEM_NAME + 1) + 8];

  format(str, sizeof(str), "{%06x}%s{FFFFFF} usado.", GetItemColor(item) >>> 8, GetItemName(item));
  SendClientMessage(playerid, -1, str);
  return 1;
}

Item: DefineItem(model, const name[], color = -1, max_stack = cellmax) {
  if (ItemPoolSize == MAX_ITEMS) {
    return INVALID_ITEM;
  }

  Items[ItemPoolSize][ITEM_MODEL] = model;
  strpack(Items[ItemPoolSize][ITEM_NAME], name, MAX_ITEM_NAME + 1 char);
  Items[ItemPoolSize][ITEM_COLOR] = color;
  Items[ItemPoolSize][ITEM_MAX_STACK] = max_stack;
  return Item: ItemPoolSize++;
}

bool: IsValidItem(Item: item) {
  return 0 <= _: item < ItemPoolSize;
}

GetItemName(Item: item) {
  new name[MAX_ITEM_NAME + 1];

  if (IsValidItem(item)) {
    strunpack(name, Items[_: item][ITEM_NAME]);
  }
  return name;
}

GetItemColor(Item: item) {
  return !IsValidItem(item) ? -1 : Items[_: item][ITEM_COLOR];
}

AddItem(player, Item: item, amount = 1, slot = -1) {
  if (!IsPlayerConnected(player)) {
    return 0;
  }

  if (!IsValidItem(item)) {
    return -1;
  }

  if (slot != -1) {
    if (!(0 <= slot < MAX_PLAYER_ITEMS)) {
      return -2;
    }
  }

  if (slot == -1) {
    for (new i; i < MAX_PLAYER_ITEMS; i++) {
      if (PlayerItems[player][i][ITEM] == item && PlayerItems[player][i][ITEM_AMOUNT] < Items[_: item][ITEM_MAX_STACK]) {
        slot = i;
        break;
      }
    }

    if (slot == -1) {
      for (new i; i < MAX_PLAYER_ITEMS; i++) {
        if (PlayerItems[player][i][ITEM] == INVALID_ITEM) {
          slot = i;
          break;
        }
      }

      if (slot == -1) {
        return -3;
      }
    }
  }

  // solução temporária para quantidade negativa
  amount = clamp(amount, 1);

  if (PlayerItems[player][slot][ITEM_AMOUNT] + amount > Items[_: item][ITEM_MAX_STACK]) {
    amount -= Items[_: item][ITEM_MAX_STACK] - PlayerItems[player][slot][ITEM_AMOUNT];

    PlayerItems[player][slot][ITEM] = item;
    PlayerItems[player][slot][ITEM_AMOUNT] = Items[_: item][ITEM_MAX_STACK];

    if (amount) {
      AddItem(player, item, amount);
    }
  } else {
    PlayerItems[player][slot][ITEM] = item;
    PlayerItems[player][slot][ITEM_AMOUNT] += amount;
  }
  return 1;
}

RemoveItem(player, slot, amount = cellmax) {
  if (!IsPlayerConnected(player)) {
    return 0;
  }

  if (PlayerItems[player][slot][ITEM] == INVALID_ITEM) {
    return -1;
  }

  if (!(PlayerItems[player][slot][ITEM_AMOUNT] = clamp((PlayerItems[player][slot][ITEM_AMOUNT] -= amount), 0))) {
    PlayerItems[player][slot][ITEM] = INVALID_ITEM;
  }
  return 1;
}

ClearItems(player, &count = 0) {
  if (!IsPlayerConnected(player)) {
    return 0;
  }

  for (new i; i < MAX_PLAYER_ITEMS; i++) {
    if (PlayerItems[player][i][ITEM] != INVALID_ITEM) {
      count += PlayerItems[player][i][ITEM_AMOUNT];

      PlayerItems[player][i][ITEM] = INVALID_ITEM;
      PlayerItems[player][i][ITEM_AMOUNT] = 0;
    }
  }

  if (!count) {
    return -1;
  }
  return 1;
}

UseItem(player, slot) {
  new Item: item = PlayerItems[player][slot][ITEM];

  if (!IsValidItem(item)) {
    return 0;
  }

  if (RemoveItem(player, slot, 1)) {
    if (!OnPlayerUseItem(player, item)) {
      return -1;
    }
  }
  return 1;
}

ShowPlayerItems(player) {
  if (!IsPlayerConnected(player)) {
    return 0;
  }

  new list[(MAX_ITEM_NAME + 1) * MAX_PLAYER_ITEMS] = "# Nome\tQtd";

  for (new i; i < MAX_PLAYER_ITEMS; i++) {
    format(list, sizeof(list), "%s\n%02d {%06x}%s\t%d", list, i + 1, GetItemColor(PlayerItems[player][i][ITEM]) >>> 8, PlayerItems[player][i][ITEM] != INVALID_ITEM ? GetItemName(PlayerItems[player][i][ITEM]) : "--", PlayerItems[player][i][ITEM] != INVALID_ITEM ? PlayerItems[player][i][ITEM_AMOUNT] : cellmax + 1);
  }

  ShowPlayerDialog(player, 4510, DIALOG_STYLE_TABLIST_HEADERS, "Seu Inventário", list, "Usar", "Fechar");
  return 1;
}

SaveItems(player) {
  new path[(MAX_PLAYER_NAME + 1) + 5], 
    name[MAX_PLAYER_NAME + 1];

  GetPlayerName(player, name, MAX_PLAYER_NAME + 1);

  format(path, sizeof(path), "%s.ini", name);

  new File: file = fopen(path, io_write);

  if (file) {
    new buffer[32];

    for (new i; i < MAX_PLAYER_ITEMS; i++) {
      format(buffer, sizeof(buffer), "%d, %d\r\n", _: PlayerItems[player][i][ITEM], PlayerItems[player][i][ITEM_AMOUNT]);

      fwrite(file, buffer);
    }

    fclose(file);
  }
}

LoadItems(player, &count = 0) {
  new path[(MAX_PLAYER_NAME + 1) + 5], 
    name[MAX_PLAYER_NAME + 1];

  GetPlayerName(player, name, MAX_PLAYER_NAME + 1);

  format(path, sizeof(path), "%s.ini", name);

  new File: file = fopen(path);

  if (file) {
    new buffer[32 * (MAX_PLAYER_ITEMS + 1)];

    while (fread(file, buffer)) {
      sscanf(buffer, "p<,>e<dd>", PlayerItems[player][count++]);
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
    SendClientMessage(playerid, -1, "/daritem [alvo] [item] [(opcional) quantidade] [(opcional) slot]");
    return 1;
  }

  switch (AddItem(player, item, amount, slot)) {
    case 0: {
      SendClientMessage(playerid, -1, "Alvo desconectado.");
    }
    case -1: {
      SendClientMessage(playerid, -1, "Item inválido.");
    }
    case -2: {
      SendClientMessage(playerid, -1, "Slot inválido.");
    }
    case -3: {
      SendClientMessage(playerid, -1, "O inventário do alvo está cheio.");
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
    SendClientMessage(playerid, -1, "/removeritem [alvo] [slot] [(opcional) quantidade]");
    return 1;
  }

  switch (RemoveItem(player, slot, amount != -1 ? amount : cellmax)) {
    case 0: {
      SendClientMessage(playerid, -1, "Alvo desconectado.");
    }
    case -1: {
      SendClientMessage(playerid, -1, "O inventário do alvo não tem um item válido neste slot.");
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
    SendClientMessage(playerid, -1, "/limparinv [alvo]");
    return 1;
  }

  new count;

  switch (ClearItems(player, count)) {
    case 0: {
      SendClientMessage(playerid, -1, "Alvo desconectado.");
    }
    case -1: {
      SendClientMessage(playerid, -1, "O inventário do alvo já está vazio.");
    }
    case 1: {
      new str[32];

      format(str, sizeof(str), "%d itens foram excluídos.", count);
      SendClientMessage(playerid, -1, str);
    }
  }
  return 1;
}
