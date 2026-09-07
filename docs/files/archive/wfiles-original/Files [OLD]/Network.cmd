@echo off
@echo rss=enabled
netsh int tcp set global rss=enabled
@echo autotuninglevel=disabled
netsh int tcp set global autotuninglevel=disabled
@echo congestionprovider=CTCP
netsh int tcp set supplemental Internet congestionprovider=CTCP
@echo ecncapability=disabled
netsh int tcp set global ecncapability=disabled
@echo ecncapability=disabled
netsh int tcp set global ecncapability=disabled
@echo initialRto=2000
netsh int tcp set global initialRto=2000
@echo rsc=disabled
netsh int tcp set global rsc=disabled
@echo nonsackrttresiliency=disabled
netsh int tcp set global nonsackrttresiliency=disabled
@echo maxsynretransmissions=2
netsh int tcp set global maxsynretransmissions=2
@echo fastopen=enabled
netsh int tcp set global fastopen=enabled
@echo fastopenfallback=enabled
netsh int tcp set global fastopenfallback=enabled
@echo hystart=enabled
netsh int tcp set global hystart=enabled
@echo pacingprofile=off
netsh int tcp set global pacingprofile=off

pause

