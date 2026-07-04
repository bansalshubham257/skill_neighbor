from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime
from sqlalchemy.orm import declarative_base, relationship
import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    google_id = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    latitude = Column(Float)
    longitude = Column(Float)
    society_id = Column(Integer, ForeignKey("societies.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    skills = relationship("Skill", back_populates="user")
    society = relationship("Society", back_populates="members")

class Society(Base):
    __tablename__ = "societies"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    latitude = Column(Float)
    longitude = Column(Float)

    members = relationship("User", back_populates="society")

class Skill(Base):
    __tablename__ = "skills"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    category = Column(String, index=True)
    title = Column(String)
    description = Column(String)
    price_type = Column(String)
    hourly_rate = Column(Float, nullable=True)
    phone_number = Column(String)

    user = relationship("User", back_populates="skills")

class AdToken(Base):
    __tablename__ = "ad_tokens"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    token_type = Column(String)
    count = Column(Integer, default=0)
    last_updated = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)
