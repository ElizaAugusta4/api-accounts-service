from pydantic import BaseModel, Field, ConfigDict
from typing import Optional

class AccountBase(BaseModel):
    name: str = Field(..., max_length=100)
    description: Optional[str] = Field(None, max_length=255)

class AccountCreate(AccountBase):
    pass

class AccountOut(AccountBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
