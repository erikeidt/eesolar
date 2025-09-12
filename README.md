This is a lightweight solar & battery monitor and controller for Enphase Envoy systems, built using Home Assistant automation platform.

It includes automation for monitoring an Envoy, a dashboard, and a live monitor web page along with rules for automation for my situation,
which is PG&E NEM2 using the TOU-D rate.

The controller uses charge from solar behavior (CP) during low light, 
then when solar output is sufficient, switches to self-consumption behavior (ZN) while climbing the reserve,
and for workdays 5pm-8pm, switches to discharge to load (DL).

To install create a folder named as you like (I call it "mypackages", so /config/mypackages/)
and add a line to your configuration.yaml as follows:

```
homeassistant:
  packages: !include_dir_named mypackages/
```

Then copy either bin/eesolar_monitor_only.yaml -or- bin/eesolar.yaml into mypackages/

Edit the yaml file to apply your Envoy's IP local address in the various rest commands.
(-Or-, you can use https://envoy.local/ but that provides an opportunity for DNS errors, so I use the direct IP address.)

For

  * monitor only: 
    * copy eesolar_monitor_only.yaml to mypackages/
    * copy www/halelm.html file to your /config/www folder, and 
    * copy the contents of .storage/lovelace.dashboard_solar into a new empty dashboard

  * monitor+controller:
    * copy eesolar.yaml to mypackages/
    * copy www/halelm.html file to your /config/www folder, and 
    * copy the contents of .storage/lovelace.dashboard_solar into a new empty dashboard
    * copy the contents of .storage/local_calendar.utility_tou_holidays.ics into a new empty calendar named "Utility TOU Holidays"

Two secret tokens are needed:
  * one for the Envoy, which you obtain using your Enlighten logon at https://entrez.enphaseenergy.com/
  * one for your Home Assistant itself, so that the monitor web page (www/halelm.html) can call back into HA for monitoring data.

(Note that the dashboard and calendar are best imported into a new empty dashboard or a new empty calendar (respectively) rather than copied as files,
since that doesn't seem to create the proper entities.)




