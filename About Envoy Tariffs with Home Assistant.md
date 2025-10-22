The Envoy uses use a tariff specification to accomplish desired behaviors regarding how the battery is to be used (charge, discharge, idle).&nbsp; 
The tariff is sent, as json text, to a REST API endpoint, namely https://envoy.local/admin/lib/tariff.json using an HTTP PUT command.&nbsp;
(This is a local endpoint &#8212; it does not use the cloud, however, it does require a jwt, which is obtained from the cloud though lasts for about a year.)

The tariff is meant to be self sufficient, including scheduling features, summer vs. winter, weekday vs. weekend, etc..&nbsp; So, set and forget.

However, the behaviors some of us we really want require dynamic adjustments.&nbsp; Because of that my approach is let Home Assistant determine what tariff and when, 
i.e. taking over the scheduling functions.&nbsp; Thus, in my tariffs, I don't bother differentiating between summer vs. winter, or even weekend vs. seekday; 
I don't bother setting complex pricings either, so I just use simple values like 0.25 and 0.5.

I use Saving mode exclusively as, among all the possible behaviors that we can accomplish, Saving mode with dynamic tariffs can accomplish them all.

Savings mode has two periods per day: on peak and off peak.

Generally speaking the off-peak behavior comes from mode key CP, while the on-peak behavior comes from one of the other mode keys.&nbsp; 
So, we can have tariffs that alternate periods between CP and one other mode key.&nbsp; 
Yet, since we can rewrite the tariff (e.g. at least once per minute), we can control the behavior more precisely than the standard set and forget.

The tariff json text comes as two parts, the first part (called the "tariff:" field is an object that) indicates the schedule and has a few other options and is the input to the REST API to set a new tariff.&nbsp;
One particular setting of interest is the "peak_rule:" field, which determines the on peak mode key setting.

The second part is the daily schedule of specific modes & times, and the envoy (re)generates this second part based on the first part when given.&nbsp;
This part is called the "schedule:" object field.&nbsp; 
It would be nice if we could write the second part directly but this does not take &#8212; the envoy ignores any second part and regenerates that second part based on the first part.

Both parts are returned in any GET or PUT to the REST API &nbsp; a slightly altered version of the input part and the envoy-generated part.&nbsp;
The return from GET or PUT looks like a json object as follows:
```
{
  tariff: ...,
  schedule: ...
}
```
The object we send looks the same but can omit the "schedule:" field, as it will be ignored and replaced anyway.&nbsp;
So, we construct a tariff and send (PUT) it to the envoy, and it returns both parts together (and we can see what it generated as schedule).

We can create tariffs that alternate between two periods where one is CP and the other is either ZN, DL, DG, or CG.&nbsp; 
As we can install them dynamically, we can choose our own scheduling, to accomplish any mode e.g. CP, ZN, DL...

Thus, for example, while the envoy has traditionally rejected tariffs that don't have at least one peak, we can send a new tariff whenver we like, so we can avoid using off peak or on peak altogether.

Here are other behaviors that can be accomplished:

1. Idle the batteries:
	* Use Peak Rule: DL
	* Set Reserve to current SoC
	* Configure tariff so that the current time is included in the peak period.
	* The DL setting sends solar to the grid, while using battery to power home load,
	  but when the Reserve is reached, then the battery stops discharging.
	  and yet won't recharge as long as the system is in DL.
	* In other words, using peak rule DL to prevent battery recharge, and yet also using Reserve to prevent battery discharge.
	  The result is idling the batteries, and this can be done at will (say when SoC reaches 90%).

	If using this approach to stop charging at some level, I would recommend to recharge the batteries to 100% from time to time,
  because the % calibration can go out of sync, but it is self-tuning in that	when the batteries will no longer take a charge for a while,
  the % is reset to 100%.

2. To have mostly self-consumption behavior,
  Where is solar powers home load and recharges battery, without overly discharging batteries:
	* Use Peak Rule: ZN
	* Use a climbing Reserve (reset reserve higher when possible, resend tariff)
	* Configure tariff so that the current time is include in peak period.
	* The ZN setting says to use solar to power the home load, then recharge batteries.

	Normally, this ZN setting will also allow discharge of the batteries when the home load is high.
	However, by using a climbing reserve we can control the discharge to accomplish an overall rising charge.

---

Mode Key Settings:

1. CP - Charge from Photovoltaics
   * Use grid for home load.
   * Send all solar to recharge batteries.
   * This is an off-peak setting, i.e. to use it now, choose a peak period that is not now

3. ZN - Zero Net
	* Self Consumption behavior.
	* Prefer to power home load from solar.
	* Use battery when solar is insufficient.
	* Use grid when battery is at reserve.
	* May occasionally pull from the grid, but attempts to send back that same amount when possible.
	* This is an on-peak setting, i.e. to use it now, choose a peak period that covers now.

4. DL - Discharge to Load
	* Power home load from batteries until reserve is reached.
  * Send all solar to the grid as long as batteries are powering the home load.
	* When the reserve is reached, will not charge batteries.
	* This is an on-peak setting, i.e. to use it now, choose a peak period that covers now.

5. DG - Discharge to Grid

6. CG - Charge from Grid

---

Here is the Home Assistant rest command I'm using:
```
  send_envoy_param_tariff: 
#   url: "https://envoy.local/admin/lib/tariff.json"
    url: "https://<ipaddr>/admin/lib/tariff.json"
    method: post                                     
    verify_ssl: false
    timeout: 60      
    content_type: "application/json"
    headers:
      Authorization: !secret enjt
    payload: >-            
      {{
        '{"tariff":{"currency":{"code":"USD"},"logger":"mylogger","date":"' +
        time | string +                              
        '","storage_settings":{"mode":"economy","operation_mode_sub_type":"","reserved_soc":' +
        reserve | round(1) | string +
        ',"very_low_soc":25,"charge_from_grid":false,"date":"' +
        time | string +
        '","opt_schedules":false},"single_rate":{"rate":0.25,"sell":0.25},' +
        '"seasons":[{"id":"all_year_long","start":"1/1",' +
        '"days":[{"id":"all_days","days":"Mon,Tue,Wed,Thu,Fri,Sat,Sun",' +
        '"must_charge_start":0,"must_charge_duration":0,"must_charge_mode":"CP","peak_rule":"' +
        peak_rule +
        '","enable_discharge_to_grid":false,"periods":[{"id":"filler","start":0,"rate":0.25},{"id":"peak-1_","start":' +
        peak_start | int | string +
        ',"rate":0.5},{"id":"filler","start":' +
        peak_end | int | string +
        ',"rate":0.25}]}]}]}}'
      }}
```
And it is invoked using an action like this:
```
action: rest_command.send_envoy_param_tariff_ex
continue_on_error: true
metadata: {}
data:
  time: "{{ now().timestamp() | int }}"
  peak_rule: ZN
  peak_start: 420
  peak_end: 1141
  reserve: 89
response_variable: response
```
The peak_start and peak_end are times of day in minutes starting with midnight as 0.&nbsp;
The peak_rule is a mode key as described above.&nbsp;
And the reserve is the battery reserve level.&nbsp;
(I have hard-coded mode:"economy" and very_low_soc:25 in the rest command template, though these can be changed and/or parameterized.)

