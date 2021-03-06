// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:analog_clock/screen_util.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import 'package:vector_math/vector_math_64.dart' show radians;

/// Total distance traveled by a second or a minute hand, each second or minute,
/// respectively.
final radiansPerTick = radians(360 / 60);

/// Total distance traveled by an hour hand, each hour, in radians.
final radiansPerHour = radians(360 / 12);

/// A basic analog clock.
///
/// You can do better than this!
class AnalogClock extends StatefulWidget {
  const AnalogClock(this.model);

  final ClockModel model;

  @override
  _AnalogClockState createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock> {
  var _now = DateTime.now();
  var _temperature = '';
  var _temperatureRange = '';
  var _condition = '';
  var _location = '';
  Timer _timer;

  static double radius = 380;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    // Set the initial values.
    _updateTime();
    _updateModel();
  }

  @override
  void didUpdateWidget(AnalogClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      _temperature = widget.model.temperatureString;
      _temperatureRange = '(${widget.model.low} - ${widget.model.highString})';
      _condition = widget.model.weatherString;
      _location = widget.model.location;
    });
  }

  void _updateTime() {
    setState(() {
      _now = DateTime.now();
      // Update once per second. Make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _now.millisecond),
        _updateTime,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context,
        width: MediaQuery.of(context).size.height * (5 / 3),
        height: MediaQuery.of(context).size.height,
        allowFontScaling: true);
    // There are many ways to apply themes to your clock. Some are:
    //  - Inherit the parent Theme (see ClockCustomizer in the
    //    flutter_clock_helper package).
    //  - Override the Theme.of(context).colorScheme.
    //  - Create your own [ThemeData], demonstrated in [AnalogClock].
    //  - Create a map of [Color]s to custom keys, demonstrated in
    //    [DigitalClock].
    final customTheme = Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).copyWith(
            // Hour hand.
            primaryColor: Color(0xFF4285F4),
            // Minute hand.
            highlightColor: Color(0xFF8AB4F8),
            // Second hand.
            accentColor: Color(0xFF669DF6),
            backgroundColor: Colors.white,
          )
        : Theme.of(context).copyWith(
            primaryColor: Color(0xFFD2E3FC),
            highlightColor: Color(0xFF4285F4),
            accentColor: Color(0xFF8AB4F8),
            backgroundColor: Colors.black,
          );

    final time = DateFormat.Hms().format(DateTime.now());
    final hour =
        DateFormat(widget.model.is24HourFormat ? 'HH' : 'hh').format(_now);
    final minute = DateFormat('mm').format(_now);
    final weatherInfo = DefaultTextStyle(
      style: TextStyle(color: customTheme.primaryColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_temperature),
          Text(_temperatureRange),
          Text(_condition),
          Text(_location),
        ],
      ),
    );

    return Semantics.fromProperties(
      properties: SemanticsProperties(
        label: 'Analog clock with time $time',
        value: time,
      ),
      child: Container(
        color: customTheme.backgroundColor,
        child: Stack(
          children: [
            // Example of a hand drawn with [CustomPainter].
            // DrawnHand(
            //   color: customTheme.accentColor,
            //   thickness: 4,
            //   size: 1,
            //   angleRadians: _now.second * radiansPerTick,
            // ),
            // DrawnHand(
            //   color: customTheme.highlightColor,
            //   thickness: 16,
            //   size: 0.9,
            //   angleRadians: _now.minute * radiansPerTick,
            // ),
            // // Example of a hand drawn with [Container].
            // ContainerHand(
            //   color: Colors.transparent,
            //   size: 0.5,
            //   angleRadians: _now.hour * radiansPerHour +
            //       (_now.minute / 60) * radiansPerHour,
            //   child: Transform.translate(
            //     offset: Offset(0.0, -60.0),
            //     child: Container(
            //       width: 32,
            //       height: 150,
            //       decoration: BoxDecoration(
            //         color: customTheme.primaryColor,
            //       ),
            //     ),
            //   ),
            // ),
            // Positioned(
            //   left: 0,
            //   bottom: 0,
            //   child: Padding(
            //     padding: const EdgeInsets.all(8),
            //     child: weatherInfo,
            //   ),
            // ),
            Positioned(
              top: ScreenUtil().setHeight(-(radius / 2)),
              left: ScreenUtil().setWidth(-(radius / 2)),
              child: Container(
                height: ScreenUtil().setHeight(radius),
                width: ScreenUtil().setWidth(radius),
                alignment: Alignment.topRight,
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: ScreenUtil().setHeight(24),
              left: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "$hour : $minute ${widget.model.is24HourFormat ? "" : _now.hour > 12 ? "PM" : "AM"}",
                  style: TextStyle(
                      fontSize: ScreenUtil().setSp(32),
                      fontFamily: "Inter",
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.all(ScreenUtil().setWidth(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "$_condition, $_temperatureRange",
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: ScreenUtil().setSp(14)),
                    ),
                    Text(
                      _location,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: ScreenUtil().setSp(14)),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: ScreenUtil().setWidth(60),
              top: ScreenUtil().setHeight(40),
              child: Container(
                height: ScreenUtil().setHeight(260),
                width: ScreenUtil().setWidth(260),
                alignment: Alignment.topRight,
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: ScreenUtil().setWidth(24),
              top: ScreenUtil().setHeight(32),
              child: Container(
                height: ScreenUtil().setHeight(80),
                width: ScreenUtil().setWidth(80),
                alignment: Alignment.topRight,
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
