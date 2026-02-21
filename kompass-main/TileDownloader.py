import urllib.request
import os
import math
import time

def deg2num(lat_deg, lon_deg, zoom):
  lat_rad = math.radians(lat_deg)
  n = 2.0 ** zoom
  xtile = int((lon_deg + 180.0) / 360.0 * n)
  ytile = int((1.0 - math.asinh(math.tan(lat_rad)) / math.pi) / 2.0 * n)
  return (xtile, ytile)

def download_tiles(min_lat, min_lon, max_lat, max_lon, min_z, max_z, output_dir):
    print(f"Downloading tiles to {output_dir}")
    os.makedirs(output_dir, exist_ok=True)
    
    total_tiles = 0
    # User-Agent is required by OSM tile servers
    headers = {
        'User-Agent': 'OfflineMapDownloader/1.0 (Student Project)'
    }
    
    for z in range(min_z, max_z + 1):
        x_min, y_max = deg2num(min_lat, min_lon, z) # min lat/lon -> bottom left -> max Y, min X
        x_max, y_min = deg2num(max_lat, max_lon, z) # max lat/lon -> top right -> min Y, max X
        
        for x in range(x_min, x_max + 1):
            for y in range(y_min, y_max + 1):
                # Apple MapKit structure is often {z}/{x}/{y} or {z}/{x}/{y}.png
                url = f"https://tile.openstreetmap.org/{z}/{x}/{y}.png"
                tile_path = os.path.join(output_dir, str(z), str(x))
                os.makedirs(tile_path, exist_ok=True)
                file_path = os.path.join(tile_path, f"{y}.png")
                
                if not os.path.exists(file_path):
                    try:
                        req = urllib.request.Request(url, headers=headers)
                        with urllib.request.urlopen(req) as response:
                            data = response.read()
                            with open(file_path, "wb") as f:
                                f.write(data)
                        print(f"Downloaded: {z}/{x}/{y}")
                        # Be gentle on OSM servers
                        time.sleep(0.1) 
                    except Exception as e:
                        print(f"Failed to download {url}: {e}")
                else:
                    print(f"Exists: {z}/{x}/{y}")
                total_tiles += 1
                
    print(f"Total tiles processed: {total_tiles}")

if __name__ == "__main__":
    # Downtown San Francisco Bounds (Approximate)
    # Keeping it tight to ensure < 25MB footprint
    MIN_LAT = 37.77
    MAX_LAT = 37.81
    MIN_LON = -122.42
    MAX_LON = -122.38
    
    # Zoom levels: 13 (city level) to 16 (street level)
    # Z17+ balloons file size significantly
    MIN_Z = 13
    MAX_Z = 16
    
    OUTPUT_DIR = "kompass.swiftpm/Resources/OfflineMapTiles"
    
    download_tiles(MIN_LAT, MIN_LON, MAX_LAT, MAX_LON, MIN_Z, MAX_Z, OUTPUT_DIR)
