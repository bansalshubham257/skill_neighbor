from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, MetaData
from sqlalchemy.orm import declarative_base, relationship
import datetime

SCHEMA = "skillneighbor"
Base = declarative_base(metadata=MetaData(schema=SCHEMA))

class User(Base):
    __tablename__ = "users"
    __table_args__ = {"schema": SCHEMA}
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    password = Column(String)
    email = Column(String, unique=True, index=True)
    phone = Column(String, nullable=True)
    latitude = Column(Float)
    longitude = Column(Float)
    society_id = Column(Integer, ForeignKey("societies.id"), nullable=True)
    last_society_change = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    skills = relationship("Skill", back_populates="user")
    society = relationship("Society", back_populates="members")

class Society(Base):
    __tablename__ = "societies"
    __table_args__ = {"schema": SCHEMA}
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    latitude = Column(Float)
    longitude = Column(Float)

    members = relationship("User", back_populates="society")

class Skill(Base):
    __tablename__ = "skills"
    __table_args__ = {"schema": SCHEMA}
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    category = Column(String, index=True)
    title = Column(String)
    description = Column(String)
    price_type = Column(String)
    hourly_rate = Column(Float, nullable=True)
    phone_number = Column(String)
    share_phone = Column(Integer, default=1)

    user = relationship("User", back_populates="skills")

class AdToken(Base):
    __tablename__ = "ad_tokens"
    __table_args__ = {"schema": SCHEMA}
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    token_type = Column(String)
    count = Column(Integer, default=0)
    last_updated = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

class SkillRequest(Base):
    __tablename__ = "skill_requests"
    __table_args__ = {"schema": SCHEMA}
    id = Column(Integer, primary_key=True, index=True)
    skill_id = Column(Integer, ForeignKey("skills.id"))
    from_user_id = Column(Integer, ForeignKey("users.id"))
    to_user_id = Column(Integer, ForeignKey("users.id"))
    status = Column(String, default="pending")
    message = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

class SkillRating(Base):
    __tablename__ = "skill_ratings"
    __table_args__ = {"schema": SCHEMA}
    id = Column(Integer, primary_key=True, index=True)
    skill_id = Column(Integer, ForeignKey("skills.id"))
    from_user_id = Column(Integer, ForeignKey("users.id"))
    to_user_id = Column(Integer, ForeignKey("users.id"))
    rating = Column(Integer)
    comment = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
