I've been using Home Assistant to automate my Envoy's battery usage for years.

I got into it because I didn't like the way the system would charge batteries from solar while at the same time pulling power from the grid to power the home load.&nbsp;
That seemed like charging the batteries from the grid to me.

While the system in Self Consumption is capable of charging from solar while also powering the home load from solar, it then will no longer understand evening peak vs. off peak Time-of-Use.

So, we can have the nice behavior in the mornings (solar being shared between home load and charging), or the nice behavior evening (using battery discharge only during the actual TOU peak rate period), 
but not necessarily both together without a mode switch, which cannot be accomplished within the Envoy's set-and-forget configuration choices.

Fortunately, the Envoy has a local REST API that allows configurations to be uploaded and downloaded using simple HTTP commands!

And Home Assistant is a great platform for doing this, and also writing rules to accomplish this.&nbsp;
And so, Home Assistant to the rescue, taking over the scheduling and rules for what tariff to use and when.

Toward my initial frustraion:

I have a rule that establishes self consumption behavior with a climbing reserve; this allows solar to run the home load and charge batteries with excess solar.&nbsp;
While also allowing the batteries to discharge a limited amount to accommodate short term high home loads.&nbsp; Only if the limit is exceeded, pull from the grid.&nbsp;
This climbing reserve locks in previously obtained charge while also still allowing some battery usage/discharge for short term home loads.&nbsp; 
The amount of lattitude can be configured and depends on how the reserve is climbed.&nbsp; 
I'm using about 1%, meaning I keep the reserve limit about 1% below the SoC, so that gives the system allowance to use about that much battery before pulling from the grid.&nbsp;
And whenver the SoC goes higher, I climb the reserve up to lock in the new charge level and save battery for TOU peak.

Then for peak hours, a rule that engages the batteries for discharge and later to idle after-peak throughout the dark evenings and mornings.

Other automations are also possible though not yet here, i.e. to stop battery charging at reaching some SoC lower than 100%, e.g. 70% as some might prefer.&nbsp;
To do this well, we would also need automation to idle the batteries, and also bring them out of idle.&nbsp;
This because, while idling and non-idling configurations are possible, going into or out of idle are not built-in features of the Envoy, so would also have to be automated externally, e.g. with HA.

---

At present I don't know how to turn on or off Storm Guard directly, as this seems to be externally automated by the Enphase Cloud dynamically making changes to the Envoy.&nbsp;
So, there's no tariff option I know of in the local Envoy.&nbsp;
And that traditionally, Storm Guard comes back on even after having been turned off.&nbsp;
However, let's note that recently Enphase App now has a "really really turn off Storm Guard option"!&nbsp;
I used to have rules that looked for the bad behavior of Storm Guard (i.e. charging from grid possibly even during a peak rate period),
and would have home assistant "jerk the system out of that" (by cycling through the other modes: true Self-Consumption and/or Full Backup before returning to Savings mode), 
but fortunately this seems no longer necessary.

---

This project is a lightweight solar & battery monitor and controller for Enphase Envoy systems, built using Home Assistant automation platform.

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
