from pydantic import BaseModel


class Detection(BaseModel):
    action_needed: bool
    os: list[str] = []
