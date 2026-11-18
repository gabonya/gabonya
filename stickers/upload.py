#!/usr/bin/env python3
"""Создаёт набор стикеров в Telegram через Bot API.

Использование:
    pip install requests
    export BOT_TOKEN=123456:ABC...      # токен бота от @BotFather
    export TG_USER_ID=123456789         # ваш числовой id (узнать у @userinfobot)
    python3 upload.py monkey "Обезьян"  # короткое имя и заголовок набора

Боту нужно хотя бы раз написать /start, иначе Telegram не даст создать набор.
"""
import json, os, sys
from pathlib import Path
import requests

HERE = Path(__file__).parent
token, user_id = os.environ["BOT_TOKEN"], int(os.environ["TG_USER_ID"])
short, title = (sys.argv[1] if len(sys.argv) > 1 else "monkey"), (sys.argv[2] if len(sys.argv) > 2 else "Обезьян")
API = f"https://api.telegram.org/bot{token}/"

def call(method, data=None, files=None):
    r = requests.post(API + method, data=data, files=files, timeout=120).json()
    if not r.get("ok"):
        sys.exit(f"{method}: {r.get('description')}")
    return r["result"]

bot = call("getMe")["username"]
name = f"{short}_by_{bot}"  # Telegram требует суффикс _by_<имя_бота>
items = json.loads((HERE / "stickers.json").read_text(encoding="utf-8"))

files, stickers = {}, []
for i, s in enumerate(items):
    files[f"s{i}"] = open(HERE / "webp" / f"{s['file']}.webp", "rb")
    stickers.append({"sticker": f"attach://s{i}", "format": "static", "emoji_list": s["emoji"]})

call("createNewStickerSet",
     data={"user_id": user_id, "name": name, "title": title, "stickers": json.dumps(stickers)},
     files=files)
print(f"Готово: https://t.me/addstickers/{name}")
