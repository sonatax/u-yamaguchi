mapboxgl.accessToken = '取得したaccessTokenを書いてね';
var allMarkers = [];

// 地図を初期化する
var mapbox = new mapboxgl.Map({
    container: 'map', // 地図を表示するコンテナID
    style: 'mapbox://styles/mapbox/streets-v11', // 表示する地図のスタイル
    center: [139.6917, 35.6895], // 東京の経度と緯度
    zoom: 15 // 地図のズームレベル
});

// map の初期化
function initMap() {
  // Googleマップインスタンスを作成
  // ここではマップを表示せず、Places Libraryの機能のみを使用します
  const map = new google.maps.Map(document.createElement('div'));

  // Placesサービスを作成
  const placesService = new google.maps.places.PlacesService(map);

  // Mapboxでの検索ボタンクリックイベント
  document.getElementById('search-button').addEventListener('click', function() {
    let searchTerm = document.getElementById('search-term').value;
    if (searchTerm) {
      fetch('https://api.mapbox.com/geocoding/v5/mapbox.places/' + encodeURIComponent(searchTerm) + '.json?access_token=' + mapboxgl.accessToken)
          .then(response => response.json())
          .then(data => {
              if (data.features.length > 0) {
                  const location = data.features[0].center;
                  searchHotels(location[1], location[0], placesService);
                  mapbox.flyTo({
                      center: location,
                      zoom: 14
                  });
              } else {
                  alert('Location not found');
              }
          }).catch(error => {
              console.error('Error:', error);
              alert('Failed to retrieve location data');
          });
    } else {
      alert('Please enter a location');
    }
  });
}

// 位置（緯度、経度）を基に周辺のホテル情報を検索する関数
function searchHotels(lat, lng, placesService) {
  // Places APIのリクエストを設定
  const request = {
    location: new google.maps.LatLng(lat, lng),
    radius: '3000', // 検索半径（メートル）
    type: ['lodging'] // 宿泊施設を検索
  };

  // Google Places APIの周辺検索を実行
  placesService.nearbySearch(request, (results, status) => {
    if (status === google.maps.places.PlacesServiceStatus.OK && results) {
      // 現在の地図上のマーカーをクリアする
      clearMarkers();

      // 検索結果を地図にマーカーとして表示
      results.forEach(place => {
        var popup = new mapboxgl.Popup({ offset: 25 })
            .setText(place.name);
        var marker = new mapboxgl.Marker()
            .setLngLat([place.geometry.location.lng(), place.geometry.location.lat()])
            .setPopup(popup)
            .addTo(mapbox);

        allMarkers.push(marker);
      });
    } else {
      alert('No hotels found');
    }
  });
}

// delete all markers
function clearMarkers() {
    // 保存されているすべてのマーカーをループし削除
    for (var i = 0; i < allMarkers.length; i++) {
        allMarkers[i].remove(); // Mapbox GL JSのremove() メソッドを使用
    }
    // 配列をリセット
    allMarkers = [];
}
