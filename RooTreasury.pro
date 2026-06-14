TARGET = RooTreasury

CONFIG += sailfishapp c++11
SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172 256x256

SOURCES += \
    src/BackupHelper.cpp \
    src/RooTreasury.cpp

HEADERS += \
    src/BackupHelper.h

LRELEASE_BIN = $$[QT_INSTALL_BINS]/lrelease
TRANSLATION_TS = translations/RooTreasury_en.ts
TRANSLATION_QM = qml/translations/RooTreasury_en.qm

translation_qm.target = $$TRANSLATION_QM
translation_qm.commands = mkdir -p qml/translations && $$LRELEASE_BIN $$TRANSLATION_TS -qm $$TRANSLATION_QM
translation_qm.depends = $$TRANSLATION_TS
QMAKE_EXTRA_TARGETS += translation_qm
PRE_TARGETDEPS += $$TRANSLATION_QM

OTHER_FILES += \
    icons/86x86/RooTreasury.png \
    icons/108x108/RooTreasury.png \
    icons/128x128/RooTreasury.png \
    icons/172x172/RooTreasury.png \
    icons/256x256/RooTreasury.png \
    icons/RooTreasury.png \
    qml/RooTreasury.qml \
    qml/images/rootgpt-avatar.png \
    qml/translations/RooTreasury_en.qm \
    qml/pages/*.qml \
    translations/RooTreasury_en.ts \
    RooTreasury.desktop
