# Name of target
TARGET = helloworld

# Path for wine executable
WINEPATH = /it/kurs/realtid/bin

# NXTOSEK root path
NXTOSEKROOT = /it/kurs/realtid/nxt/nxtosek

########################################################################

TARGET_SOURCES := \
        $(TARGET).c
TOPPERS_OSEK_OIL_SOURCE := ./$(TARGET).oil

PATH := $(WINEPATH):$(PATH)

O_PATH ?= build

include $(NXTOSEKROOT)/ecrobot/ecrobot.mak
