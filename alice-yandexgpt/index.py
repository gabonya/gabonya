# Навык Алисы, который отвечает через YandexGPT.
#
# Запускается как функция Yandex Cloud Functions (Python 3.12), точка входа index.handler.
# Алиса передаёт запрос прямо в event, функция возвращает ответ в формате Яндекс Диалогов.
#
# Переменные окружения:
# FOLDER_ID - ID каталога Yandex Cloud (обязательно)
# MODEL - yandexgpt-lite (по умолчанию, быстрее) или yandexgpt
# API_KEY - необязательно: API-ключ сервисного аккаунта; если не задан,
# используется IAM-токен сервисного аккаунта самой функции
import json
import os
import urllib.error
import urllib.request

GPT_URL = "https://llm.api.cloud.yandex.net/foundationModels/v1/completion"
GPT_TIMEOUT = 2.4          # Алиса ждёт ответа около 3 секунд
MAX_TOKENS = 150           # короткий ответ быстрее генерируется и удобнее на слух
HISTORY_PAIRS = 3          # сколько последних реплик помнить
HISTORY_CHARS = 160        # обрезка каждой реплики, чтобы уложиться в лимит состояния сессии
REPLY_LIMIT = 1000         # Алиса принимает не больше 1024 символов текста

SYSTEM_PROMPT = (
    "Ты голосовой помощник в умной колонке. Отвечай по-русски, кратко: 1-3 предложения, "
    "простыми словами, без списков, таблиц, ссылок, эмодзи и markdown, потому что ответ "
    "зачитывается вслух. Если вопрос неясен, коротко переспроси."
)

EXIT_WORDS = {"хватит", "стоп", "выход", "выйти", "закончить", "пока", "до свидания"}
HELP_WORDS = {"помощь", "что ты умеешь"}


def _auth_header(context):
    api_key = os.environ.get("API_KEY")
    if api_key:
        return "Api-Key " + api_key
    token = getattr(context, "token", None) or {}
    access = token.get("access_token") if isinstance(token, dict) else None
    if not access:
        raise RuntimeError("нет API_KEY и у функции не указан сервисный аккаунт")
    return "Bearer " + access


def ask_gpt(question, history, context):
    folder = os.environ["FOLDER_ID"]
    model = os.environ.get("MODEL", "yandexgpt-lite")
    messages = [{"role": "system", "text": SYSTEM_PROMPT}]
    for user_text, bot_text in history:
        messages.append({"role": "user", "text": user_text})
        messages.append({"role": "assistant", "text": bot_text})
    messages.append({"role": "user", "text": question})
    body = {
        "modelUri": f"gpt://{folder}/{model}/latest",
        "completionOptions": {"stream": False, "temperature": 0.5, "maxTokens": str(MAX_TOKENS)},
        "messages": messages,
    }
    req = urllib.request.Request(
        GPT_URL,
        data=json.dumps(body).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "Authorization": _auth_header(context),
            "x-folder-id": folder,
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=GPT_TIMEOUT) as resp:
        data = json.load(resp)
    return data["result"]["alternatives"][0]["message"]["text"].strip()


def _reply(text, end=False, history=None):
    out = {
        "version": "1.0",
        "response": {"text": text[:REPLY_LIMIT], "end_session": end},
    }
    if history is not None:
        out["session_state"] = {"h": history}
    return out


def handler(event, context):
    request = event.get("request", {}) or {}
    session = event.get("session", {}) or {}
    command = (request.get("command") or "").strip()
    original = (request.get("original_utterance") or command).strip()
    state = (event.get("state", {}) or {}).get("session", {}) or {}
    history = state.get("h", []) if isinstance(state.get("h"), list) else []

    if command == "ping":  # служебная проверка Яндекс Диалогов
        return _reply("pong")
    if session.get("new") and not command:
        return _reply("Привет! Я на связи с YandexGPT. Задайте вопрос. Чтобы выйти, скажите «хватит».", history=[])
    if not command:
        return _reply("Не расслышала вопрос. Повторите, пожалуйста.", history=history)
    if command.lower() in EXIT_WORDS:
        return _reply("Хорошо, до встречи!", end=True)
    if command.lower() in HELP_WORDS:
        return _reply("Задайте любой вопрос, а я спрошу YandexGPT и коротко отвечу. Чтобы выйти, скажите «хватит».", history=history)

    try:
        answer = ask_gpt(original, history, context)
    except (TimeoutError, urllib.error.URLError) as e:
        if isinstance(getattr(e, "reason", None), TimeoutError) or isinstance(e, TimeoutError):
            return _reply("Не успела придумать ответ. Спросите, пожалуйста, ещё раз или покороче.", history=history)
        print("GPT error:", repr(e), getattr(e, "read", lambda: b"")()[:500])
        return _reply("Не получилось связаться с YandexGPT. Попробуйте чуть позже.", history=history)
    except Exception as e:  # noqa: BLE001 - навык должен ответить в любом случае
        print("Unexpected error:", repr(e))
        return _reply("Что-то пошло не так. Попробуйте ещё раз.", history=history)

    history = (history + [[original[:HISTORY_CHARS], answer[:HISTORY_CHARS]]])[-HISTORY_PAIRS:]
    return _reply(answer, history=history)
