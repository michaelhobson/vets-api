# frozen_string_literal: true

FactoryBot.define do
  # WKT is a "well-known-text" representation of a polygon. These polygons complete a
  # circuit but are still truncated versions of those that will appear in actual data.

  factory :ten_mins_648, class: 'DrivetimeBand' do
    # rubocop:disable Layout/LineLength
    wkt_polygon = 'POLYGON((-122.686944 45.4994139, -122.6860642 45.4933675, -122.6764727 45.4937585, -122.6778245 45.5001358, -122.6869226 45.4993838))'
    # rubocop:enable Layout/LineLength

    vha_facility_id { '648' }
    name { '648 : 0 - 10' }
    min { 0 }
    max { 10 }
    unit { 'minutes' }
    polygon { wkt_polygon }
  end

  factory :twenty_mins_648, class: 'DrivetimeBand' do
    # rubocop:disable Layout/LineLength
    wkt_polygon = 'POLYGON((-122.6999474 45.50364, -122.7002048 45.5040611, -122.7178431 45.499459, -122.7177143 45.4991883, -122.7073288 45.4695214, -122.689476 45.4712067, -122.6434708 45.4781884, -122.6455307 45.4921491, -122.6554871 45.5215034, -122.7207184 45.5133242, -122.7179718 45.4996094, -122.7002048 45.5043017, -122.7004623 45.5056852, -122.6739407 45.5097755, -122.6629543 45.4926304, -122.6932526 45.4879973, -122.6999474 45.50364))'
    # rubocop:enable Layout/LineLength

    vha_facility_id { '648' }
    name { '648 : 10 - 20' }
    min { 10 }
    max { 20 }
    unit { 'minutes' }
    polygon { wkt_polygon }
  end

  factory :ten_mins_648GI, class: 'DrivetimeBand' do
    # rubocop:disable Layout/LineLength
    wkt_polygon = 'POLYGON((-122.6785326 45.5248408, -122.6821804 45.5196391, -122.6711941 45.5163013, -122.6663446 45.5228263, -122.6775885 45.5260735, -122.6785326 45.5248408))'
    # rubocop:enable Layout/LineLength

    vha_facility_id { '648GI' }
    name { '648GI : 0 - 10' }
    min { 0 }
    max { 10 }
    unit { 'minutes' }
    polygon { wkt_polygon }
  end

  factory :twenty_mins_648GI, class: 'DrivetimeBand' do
    # rubocop:disable Layout/LineLength
    wkt_polygon = 'POLYGON((-122.6887035 45.5340705, -122.7169847 45.542968, -122.7170706 45.5427275, -122.7183151 45.5405033, -122.7488708 45.5063469, -122.722435 45.4945557, -122.646904 45.4740958, -122.634201 45.4887796, -122.5981522 45.5356938, -122.6922226 45.5667079, -122.7171135 45.5432686, -122.6879311 45.534792, -122.6862144 45.5379784, -122.645359 45.5260735, -122.6617527 45.4993086, -122.7044964 45.5115799, -122.6887035 45.5340705))'
    # rubocop:enable Layout/LineLength

    vha_facility_id { '648GI' }
    name { '648GI : 10 - 20' }
    min { 10 }
    max { 20 }
    unit { 'minutes' }
    polygon { wkt_polygon }
  end

  factory :sixty_mins_648A4, class: 'DrivetimeBand' do
    # rubocop:disable Layout/LineLength
    wkt_polygon_60 = 'POLYGON((-123.293727 45.65712, -123.278182 45.655242, -123.262636 45.73551, -123.24709 45.73413, -123.231545 45.724, -123.215999 45.73662, -123.200453 45.73715, -123.184908 45.71415, -123.169362 45.728426, -123.153816 45.72368, -123.138271 45.720583, -123.122725 45.722123, -123.107179 45.70242, -123.091634 45.707012, -123.076088 45.733481, -123.060542 45.73118, -123.044997 45.69834, -123.029451 45.690555, -123.013905 45.67689, -122.99836 45.76784, -122.982814 45.76937, -122.967268 45.82637, -122.951723 45.83121, -122.936177 45.833723, -122.920632 45.831696, -122.905086 45.834459, -122.88954 45.81947, -122.88954 45.834459, -122.873995 46.07648, -122.858449 46.06016, -122.842903 46.051238, -122.827358 46.01723, -122.811812 45.998838, -122.796266 45.98424, -122.780721 45.95109, -122.765175 45.95946, -122.749629 45.957567, -122.734084 45.95469, -122.718538 45.957848, -122.702992 45.957704, -122.687447 45.94694, -122.671901 45.9403, -122.656355 45.93339, -122.64081 45.932461, -122.625264 45.93069, -122.609719 45.88731, -122.594173 45.87775, -122.578627 45.89577, -122.563082 45.886236, -122.547536 45.866891, -122.53199 45.863026, -122.516445 45.86911, -122.500899 45.85824, -122.485353 45.8349, -122.469808 45.80335, -122.454262 45.792416, -122.438716 45.744718, -122.423171 45.67262, -122.407625 45.678669, -122.392079 45.67911, -122.376534 45.675586, -122.360988 45.67889, -122.345442 45.65919, -122.329897 45.628466, -122.314351 45.629925, -122.298805 45.63022, -122.28326 45.62699, -122.267714 45.609827, -122.252169 45.60177, -122.236623 45.59497, -122.221077 45.589206, -122.205532 45.593677, -122.189986 45.5957, -122.17444 45.590864, -122.158895 45.58852, -122.143349 45.578045, -122.127803 45.57958, -122.112258 45.5812, -122.096712 45.58633, -122.081166 45.59295, -122.065621 45.598825, -122.050075 45.60394, -122.034529 45.61058, -122.018984 45.61304, -122.003438 45.615343, -122.003438 45.61245, -122.018984 45.61003, -122.034529 45.601265, -122.050075 45.593025, -122.065621 45.59233, -122.081166 45.58616, -122.096712 45.58073, -122.112258 45.57812, -122.127803 45.52544, -122.143349 45.51838, -122.158895 45.51807, -122.17444 45.50613, -122.189986 45.504295, -122.205532 45.50446, -122.221077 45.500919, -122.236623 45.49738, -122.252169 45.504275, -122.267714 45.47232, -122.28326 45.47224, -122.298805 45.46788, -122.314351 45.467849, -122.329897 45.46361, -122.345442 45.33921, -122.360988 45.342934, -122.376534 45.34573, -122.392079 45.28532, -122.407625 45.28267, -122.423171 45.292843, -122.438716 45.28592, -122.454262 45.26584, -122.469808 45.270355, -122.485353 45.276852, -122.500899 45.2658, -122.516445 45.25055, -122.53199 45.24695, -122.547536 45.231632, -122.563082 45.17908, -122.578627 45.18177, -122.594173 45.16643, -122.609719 45.14323, -122.625264 45.12856, -122.64081 45.128581, -122.656355 45.11421, -122.671901 45.114237, -122.687447 45.09977, -122.702992 45.09981, -122.718538 45.09975, -122.734084 45.098801, -122.749629 45.10006, -122.765175 45.09987, -122.780721 45.088498, -122.796266 45.087591, -122.811812 45.081088, -122.827358 45.066814, -122.842903 45.068464, -122.858449 45.07719, -122.873995 45.07517, -122.88954 45.07974, -122.905086 45.07974, -122.920632 45.03262, -122.936177 45.02691, -122.951723 45.02442, -122.967268 45.02784, -122.982814 45.00419, -122.99836 44.97696, -123.013905 44.98194, -123.029451 45.042428, -123.02687 45.05734, -123.024544 45.068132, -123.029477 45.078925, -123.03459 45.089717, -123.027051 45.100509, -123.020687 45.111301, -122.99433 45.122093, -123.0072 45.132885, -123.00605 45.143677, -123.00272 45.154469, -122.997755 45.165261, -122.993105 45.176053, -123.01089 45.186845, -122.985697 45.197637, -123.02452 45.208429, -123.03564 45.219221, -122.99449 45.230013, -122.99696 45.240805, -122.99193 45.251597, -122.99168 45.26239, -123.01414 45.273182, -122.995115 45.283974, -122.98511 45.294766, -122.97946 45.305558, -122.99092 45.31635, -122.990909 45.327142, -122.972455 45.337934, -122.943215 45.348726, -122.96314 45.359518, -122.97571 45.37031, -123.00008 45.381102, -122.99315 45.391894, -122.99285 45.402686, -123.03351 45.413478, -123.03359 45.42427, -123.044997 45.45097, -123.060542 45.46715, -123.076088 45.476235, -123.091634 45.483127, -123.107179 45.48283, -123.122725 45.48303, -123.138271 45.48233, -123.153816 45.51084, -123.169362 45.539187, -123.184908 45.566211, -123.200453 45.56973, -123.215999 45.566358, -123.231545 45.57757, -123.24709 45.568251, -123.262636 45.567601, -123.278182 45.63085, -123.293727 45.63586, -123.293727 45.65712))'
    # rubocop:enable Layout/LineLength

    vha_facility_id { '648A4' }
    name { '648A4 : 0 - 10' }
    min { 50 }
    max { 60 }
    unit { 'minutes' }
    polygon { wkt_polygon_60 }
  end
end