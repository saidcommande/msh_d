'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "9de3c795ace394eb8851212aad2767f9",
"assets/AssetManifest.bin.json": "c2ef9a1158b14d71016117a3117f793b",
"assets/AssetManifest.json": "68be8eeb88c6d3e3ad922c6b171a8fd7",
"assets/assets/commande_icon.png": "db7197117cab651c3aede1613b15932b",
"assets/assets/data/default_catalogue.json": "b8f0cfc7eed4188765662d267799c579",
"assets/assets/images/gotaspain/IMG_20200730_201146.jpg": "547a18618f9f8aa7c4d4375fee26e672",
"assets/assets/images/gotaspain/prod_1752440345.png": "2379dfce0e581f523f3df4cf52d91d80",
"assets/assets/images/gotaspain/prod_1752440425.png": "ec1fd5875948434518a2e9aeefd07d4d",
"assets/assets/images/gotaspain/prod_1752440525.png": "06392e31cb74969c8392aaf99a1ad900",
"assets/assets/images/gotaspain/prod_1752440616.png": "c290d609a7609dea6e37620f36f06ff9",
"assets/assets/images/gotaspain/prod_1752440890.png": "274c09c70821508fd0fe313a96dd0f73",
"assets/assets/images/gotaspain/prod_1752440916.png": "70928403e38fe85eb46cbb3f6a1e08fc",
"assets/assets/images/gotaspain/prod_1752441056.png": "8b888d4b29a36fef425f859edf1c8aa8",
"assets/assets/images/gotaspain/prod_1752441236.png": "405071b0183d277bb52d1ec12f535b30",
"assets/assets/images/gotaspain/prod_1752441326.png": "a1f7eea44cb868d79e8e28530f1e6665",
"assets/assets/images/gotaspain/prod_1752441428.png": "d5d7d5cbc69dffe44c5aaf9b30a3de5b",
"assets/assets/images/gotaspain/prod_1752441534.png": "63432d2d55ecbb913bde76dc6f27276e",
"assets/assets/images/gotaspain/prod_1752441626.png": "57e22b85a3021098ab004a627a186f83",
"assets/assets/images/gotaspain/prod_1752441701.png": "d182b9b61ea69803bfb29578fe4cbadc",
"assets/assets/images/gotaspain/prod_1752441795.png": "3fdfe0d6f02e47f8d437beae95e8163e",
"assets/assets/images/gotaspain/prod_1752441998.png": "12cf64ec159c0c8a6660d75217c001c7",
"assets/assets/images/gotaspain/prod_1752442024.png": "06dfcd42587dd47277c73f211a3b3e83",
"assets/assets/images/gotaspain/prod_1752442124.png": "46b3353e5d0bab48a867c1903bc9f343",
"assets/assets/images/gotaspain/prod_1752442243.png": "30f009129551dc8dd6fcf8862afd9e5c",
"assets/assets/images/gotaspain/prod_1752442366.png": "68a31492406a3a38453235ce11e0f242",
"assets/assets/images/gotaspain/prod_1752442451.png": "a8e2f473817ce783075fbada5a1d549f",
"assets/assets/images/gotaspain/prod_1752442552.png": "bb2056760c8c8586a7933b6d40de9f99",
"assets/assets/images/gotaspain/prod_1752442632.png": "33bc9ec6783d3144b979bc249c63c92d",
"assets/assets/images/gotaspain/prod_1752442885.png": "e443c04c73f64272682d658624ec01da",
"assets/assets/images/gotaspain/prod_1752442947.png": "0de61e0b8ed55a35fc2785d6100bb87d",
"assets/assets/images/gotaspain/prod_1752443042.png": "9768f02a756308a1773431e8166e8474",
"assets/assets/images/gotaspain/prod_1752443210.png": "694ab24f0e9f15183527cea755665028",
"assets/assets/images/gotaspain/prod_1752443288.png": "687ed7e76a61f483051a112b39f0f300",
"assets/assets/images/gotaspain/prod_1752443398.png": "a37bda30be282ea2f572abc5c5a678e0",
"assets/assets/images/gotaspain/prod_1752443483.png": "8b60986bdac5ab458e170f5b6893e99c",
"assets/assets/images/gotaspain/prod_1752443636.png": "e44c7f5b009af5a24a1a58697b0f4760",
"assets/assets/images/gotaspain/prod_1752443801.png": "a705f9431fe1d2af6e974068e27702d2",
"assets/assets/images/gotaspain/prod_1752443916.png": "e9f2ebc21be34ee549a00cf01899b24a",
"assets/assets/images/gotaspain/prod_1752443972.png": "ea35c09edad0d425547b350c7134c314",
"assets/assets/images/gotaspain/prod_1752444471.png": "13f1f7a4764c6ae98fc1c68fcea24e68",
"assets/assets/images/gotaspain/prod_1752444544.png": "d16bf4da1c6deba26e462f9dd2f39a36",
"assets/assets/images/gotaspain/prod_1752444764.png": "d2f6d8ca301c41abedef5b886997465c",
"assets/assets/images/gotaspain/prod_1752444885.png": "cd17f3eb9d703c87e9768a634ad8963a",
"assets/assets/images/gotaspain/prod_1752445018.png": "bc20b1d162f8343541a9ee4dba9f84d0",
"assets/assets/images/gotaspain/prod_1752445194.png": "7e76e09bfe70f9afa9d0b43a4a684ad0",
"assets/assets/images/gotaspain/prod_1752445313.png": "b540c3bd257562fc8e34541517d512fe",
"assets/assets/images/gotaspain/prod_1752445434.png": "260284081e8029ff9fc15593a944aded",
"assets/assets/images/gotaspain/prod_1752445531.png": "746cc119cde725c998509063449b026e",
"assets/assets/images/gotaspain/prod_1752850092.jpeg": "5a3c4b307159280c18c16de0ced9a210",
"assets/assets/images/gotaspain/prod_1752850193.jpeg": "c14d81f78ba736d20ce56f278d226adc",
"assets/assets/images/gotaspain/prod_1752850317.jpeg": "eb539d1a65c0c928b16531a575654e6b",
"assets/assets/images/gotaspain/prod_1752850502.jpeg": "4504fb1b269a007f788594ba9910a6b0",
"assets/assets/images/gotaspain/prod_1752850600.jpeg": "9629b3a837e15c549352cb37044f63fa",
"assets/assets/images/gotaspain/prod_1752850641.jpeg": "3ec846a84fcc89ebec8345b4b3df775f",
"assets/assets/images/gotaspain/prod_1752850708.jpeg": "da2c6174ca9fff67a0358c7c80b6184f",
"assets/assets/images/gotaspain/prod_1752850839.jpeg": "2346d015fba319e80996340101f4737f",
"assets/assets/images/gotaspain/prod_1752850966.jpeg": "345da40359921d9577574d9c45398cb5",
"assets/assets/images/gotaspain/prod_1752851023.jpeg": "c53b240a6f11bab2b0c5adae38bd6a3b",
"assets/assets/images/gotaspain/prod_1752851127.jpeg": "fdd19fa100c94041a6ec4576d4245673",
"assets/assets/images/gotaspain/prod_1752851197.jpeg": "1035d7ac3e149717d35bdaaaa3e35321",
"assets/assets/images/gotaspain/prod_1752851288.jpeg": "bc8d26f23c7d0165dc22caba604060e5",
"assets/assets/images/gotaspain/prod_1752851351.jpeg": "11c0868673a747f7197c5d428e8ad570",
"assets/assets/images/gotaspain/prod_1752851610.jpeg": "046bee58a57b02c2bc126e7ddf9af95f",
"assets/assets/images/gotaspain/prod_1752851746.jpeg": "a8226bc1e79dbaf3ee05e1c77f076d42",
"assets/assets/images/gotaspain/prod_1752851899.jpeg": "94190853160ed7039d27036db7505c8c",
"assets/assets/images/gotaspain/prod_1752851983.jpeg": "f9a03adc914f82060e97e9a3bdb9083c",
"assets/assets/images/gotaspain/prod_1752852057.jpeg": "20917e533a0cdafc52e601a7503faa9c",
"assets/assets/images/gotaspain/prod_1752852126.jpeg": "702443a7e77d30b3cf4c5ec3623dab5a",
"assets/assets/images/gotaspain/prod_1752852194.jpeg": "0c6bdd90a8c62a451a9c99986bb2d696",
"assets/assets/images/gotaspain/prod_1752852268.jpeg": "a145483e365970d557a45323cd1590e9",
"assets/assets/images/gotaspain/prod_1752852468.jpeg": "a145483e365970d557a45323cd1590e9",
"assets/assets/images/gotaspain/prod_1752852517.jpeg": "00af727d37760d162287f6139ac66744",
"assets/assets/images/gotaspain/prod_1752855814.jpeg": "f9700888140ee053a6834e5af1b434b1",
"assets/assets/images/gotaspain/prod_1752855861.jpeg": "a3fa3f9daa64672c3982efa1df5e69ed",
"assets/assets/images/gotaspain/prod_1752855957.jpeg": "8875a74a22feaa4d7b62615b1bd0d9e5",
"assets/assets/images/gotaspain/prod_1752858590.jpeg": "4978b1cb1edee5a1d5d0f6123088342e",
"assets/assets/images/gotaspain/prod_1752858690.jpeg": "131b8ee744e25bebe00b99feece6384d",
"assets/assets/images/gotaspain/prod_1752858790.jpeg": "158f3cba8b1c072953aa2540d43149e2",
"assets/assets/images/gotaspain/prod_1752858903.jpeg": "df44e10bc5e6ad2228cb254c1c3b4e26",
"assets/assets/images/gotaspain/prod_1752858995.jpeg": "f1ba5917cda3533cc508ea2a280b9d3d",
"assets/assets/images/gotaspain/prod_1752859112.jpeg": "5c77f8ef9a92e4a27ade2859e1f33f1b",
"assets/assets/images/gotaspain/prod_1752859213.jpeg": "a0f4160b22dd96bf859d6161630edb40",
"assets/assets/images/gotaspain/prod_1752859406.jpeg": "d4635f52379824063006b551749e4f12",
"assets/assets/images/gotaspain/prod_1752859478.jpeg": "be3493ad9d3de9b659c49250c08c77e1",
"assets/assets/images/gotaspain/prod_1752859541.jpeg": "8713a074ca814ca12ab8dbbedb6fd0e7",
"assets/assets/images/gotaspain/prod_1752859621.jpeg": "4c229ed5ec14ebfb9d409876385a6afa",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "3c3d56a1505b7c0d3c5274847b4bd9da",
"assets/NOTICES": "4ec662391400583351fee6095fe11cff",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"data/catalog.json": "1335c300731f2fb85bc064e1f2fc1383",
"favicon.png": "db7197117cab651c3aede1613b15932b",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"flutter_bootstrap.js": "515a48a22058d7c96ef67acd025c4f3f",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "2978bf896197d9708d48402122546fe2",
"/": "2978bf896197d9708d48402122546fe2",
"main.dart.js": "850c2e2feea09faf786fd3e4c0a487f0",
"manifest.json": "0e7b451acb3e124a4f6fa5b937d9796b",
"version.json": "03a589ff19ea3e2037ccac63dc30c189"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
