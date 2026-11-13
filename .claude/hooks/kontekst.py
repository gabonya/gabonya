#!/usr/bin/env python3
"""Хук UserPromptSubmit: счётчик контекста для правила «Контроль контекста».

Модель сама не видит, сколько токенов занял чат. Хук считает это по стенограмме
сессии (поле usage последнего ответа: input + cache_creation + cache_read) и на
порогах подкладывает модели строку-сигнал. Ниже порога молчит и ничего не стоит.

Пороги — из регламента: 300 000 → предложить новый чат, 400 000 → настаивать.
Каждый порог объявляется один раз; после второго — напоминание раз в N сообщений.
Если контекст упал ниже первого порога (сжатие, новая сессия) — объявления
сбрасываются и сработают снова.
"""
import json
import os
import sys
import tempfile

THRESHOLD_SOFT = 300_000   # предложить новый чат, решение за пользователем
THRESHOLD_HARD = 400_000   # настаивать, предупредить о падении качества
REMIND_EVERY = 5           # после жёсткого порога — напоминать раз в N сообщений

SOFT_TEXT = (
    "<счётчик-контекста>\n"
    "Контекст этого чата: {ctx:,} токенов. Порог {soft:,} пройден.\n"
    "По правилу «Контроль контекста»: предложи пользователю выбор. Если задача "
    "та же и не закончена, а место съели чтение файлов и логи — /compact, и назови, "
    "что сохранить: «/compact сохрани …». Если кусок закончен, тем несколько или "
    "началась вторая задача — новый чат, и сразу дай стартовое сообщение "
    "(контекст · сделано · пробовали и отбросили · дальше · важное дословно), "
    "сверив его с чатом. Решение за пользователем: предложил один раз — дальше "
    "не дёргай, пока не наступит следующий порог.\n"
    "</счётчик-контекста>"
)

HARD_TEXT = (
    "<счётчик-контекста>\n"
    "Контекст этого чата: {ctx:,} токенов. Порог {hard:,} пройден.\n"
    "По правилу «Контроль контекста»: настойчиво рекомендуй новый чат и прямо "
    "предупреди, что дальше качество ответов будет падать. Дай стартовое "
    "сообщение для нового чата, сверенное с этим чатом по списку: решения · "
    "ограничения · открытые вопросы · точные цифры, имена, ссылки · что отбросили.\n"
    "</счётчик-контекста>"
)


def context_size(transcript_path):
    """Контекст последнего запроса к модели = входные токены его usage."""
    try:
        with open(transcript_path, "rb") as f:
            lines = f.read().splitlines()
    except OSError:
        return None
    for raw in reversed(lines):
        if b'"usage"' not in raw:
            continue
        try:
            rec = json.loads(raw)
        except ValueError:
            continue
        usage = (rec.get("message") or {}).get("usage")
        if not usage:
            continue
        return (
            usage.get("input_tokens", 0)
            + usage.get("cache_creation_input_tokens", 0)
            + usage.get("cache_read_input_tokens", 0)
        )
    return None


def state_path(session_id):
    safe = "".join(ch for ch in session_id if ch.isalnum() or ch in "-_") or "unknown"
    return os.path.join(tempfile.gettempdir(), f"kontekst-{safe}.json")


def load_state(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return {"soft": False, "hard": False, "since_hard": 0}


def save_state(path, state):
    try:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(state, f)
    except OSError:
        pass


def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0
    transcript = data.get("transcript_path")
    if not transcript:
        return 0
    ctx = context_size(transcript)
    if ctx is None:
        return 0

    path = state_path(data.get("session_id", ""))
    state = load_state(path)
    text = None

    if ctx < THRESHOLD_SOFT:
        # после сжатия или в новой сессии — пороги снова активны
        state = {"soft": False, "hard": False, "since_hard": 0}
    elif ctx >= THRESHOLD_HARD:
        if not state["hard"]:
            state["hard"] = True
            state["since_hard"] = 0
            text = HARD_TEXT
        else:
            state["since_hard"] += 1
            if state["since_hard"] >= REMIND_EVERY:
                state["since_hard"] = 0
                text = HARD_TEXT
    else:
        if not state["soft"]:
            state["soft"] = True
            text = SOFT_TEXT

    save_state(path, state)
    if text:
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "UserPromptSubmit",
                "additionalContext": text.format(
                    ctx=ctx, soft=THRESHOLD_SOFT, hard=THRESHOLD_HARD),
            }
        }, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
