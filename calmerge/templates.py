from pathlib import Path

import jinja2
from aiohttp import web
from yarl import URL

from .config import CalendarConfig

TEMPLATES_DIR = Path(__file__).resolve().parent / "templates"


async def config_context_processor(request: web.Request) -> dict:
    return {"config": request.app["config"]}


@jinja2.pass_context
def calendar_url(context: dict, calendar_config: CalendarConfig) -> URL:
    request: web.Request = context["request"]
    config = context["config"]
    calendar_url = context["url"](context, "calendar", slug=calendar_config.slug)

    url = request.url.with_path(calendar_url.path)

    if calendar_config.auth is None:
        return url.with_scheme("https")
    else:
        url = url.with_user(calendar_config.auth.username).with_password(
            calendar_config.auth.password
        )
    # if config.listing.enabled and config.listing.auth is not None:
    #     url = url.with_user(config.listing.auth.username).with_password(
    #         config.listing.auth.password
    #     )

    return url.with_scheme("https")
