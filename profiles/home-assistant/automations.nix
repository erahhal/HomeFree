[
  {
    alias = "Outdoor String Lights On";
    trigger = {
      platform = "sun";
      event = "sunset";
      offset = 0;
    };
    condition = {
      condition = "time";
      before = "00:00:00";
      weekday = [
        "fri"
        "sat"
      ];
      after = "00:00:00";
    };
    action = {
      type = "turn_on";
      device_id = "8246ac831671d63c51879e1ee50d69cb";
      entity_id = "switch.enbrighten_outdoor_plug";
      domain = "switch";
    };
  }
]
