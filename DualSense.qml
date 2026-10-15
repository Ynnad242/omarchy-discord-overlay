import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

// PS5 DualSense (Midnight Black) on a 340×268 canvas. The outline, triggers,
// bumpers and every button position were traced from a reference render of
// the real controller, so the proportions match. Matte black wings around a
// blue-grey core whose seams run down the inside of the grips; L2/R2 press
// down towards the body and fill blue as they're pulled.
Item {
  id: ds

  property var buttons: ({})
  property var axes: ({})

  width: 340
  height: 268

  function b(name) { return !!(ds.buttons && ds.buttons[name]) }
  function a(name) { return (ds.axes && ds.axes[name]) || 0 }
  // How far a trigger is pulled, 0..1 in whole percents. The analog axis wins:
  // the DualSense also sends a digital "L2 pressed" early in the pull, which
  // only counts for pads without analog triggers.
  function pull(axis, btn) {
    const v = ds.a(axis)
    return v > 0 ? Math.round(v * 100) / 100 : ds.b(btn) ? 1 : 0
  }

  // Rim light on the outlines so the black controller stays visible over
  // dark game scenes.
  readonly property color edge: "#62666f"
  readonly property color glow: "#3d7bff" // light bars, and anything held down
  readonly property color symbol: "#e6e8ec"
  // Layers are rendered at this multiple of the canvas so they stay sharp
  // when the widget is scaled up.
  readonly property real detail: 3

  // Traced paths (left side for the mirrored parts).
  readonly property string bodyPath: "M 168.4 45.8 C 167.3 45.8 165.2 45.8 163.6 45.8 C 162.0 45.8 160.4 45.8 158.7 45.9 C 157.1 45.9 155.5 46.0 153.9 46.1 C 152.3 46.2 150.7 46.3 149.1 46.4 C 147.5 46.5 145.9 46.6 144.3 46.7 C 142.7 46.8 141.1 46.8 139.5 46.9 C 137.8 46.9 136.2 46.9 134.6 46.9 C 133.0 47.0 131.4 47.1 129.8 47.3 C 128.2 47.4 126.6 47.6 125.0 47.7 C 123.4 47.9 121.8 48.0 120.2 48.1 C 118.7 48.3 117.2 48.6 115.6 48.8 C 114.0 49.0 112.4 49.1 110.8 49.3 C 109.3 49.5 107.8 50.0 106.2 50.2 C 104.7 50.5 103.0 50.6 101.4 50.8 C 99.8 51.0 98.2 51.2 96.6 51.4 C 95.1 51.6 93.4 52.2 92.1 51.9 C 90.7 51.6 89.4 50.7 88.5 49.7 C 87.7 48.6 88.1 46.5 87.1 45.6 C 86.2 44.7 84.4 44.4 82.9 44.1 C 81.4 43.7 79.7 43.7 78.1 43.7 C 76.5 43.6 74.9 43.6 73.3 43.7 C 71.7 43.7 70.1 43.7 68.5 43.9 C 67.0 44.1 65.5 44.6 64.0 45.0 C 62.4 45.4 60.9 45.7 59.5 46.2 C 58.0 46.7 56.6 47.3 55.2 47.9 C 53.8 48.5 52.3 49.1 51.0 49.9 C 49.6 50.7 48.2 51.5 47.1 52.5 C 46.0 53.5 45.0 54.8 44.3 56.1 C 43.5 57.3 43.5 58.9 42.7 59.9 C 41.8 61.0 40.0 61.3 39.0 62.3 C 38.0 63.4 37.4 65.0 36.7 66.4 C 36.0 67.7 35.3 69.1 34.6 70.5 C 34.0 71.8 33.4 73.3 32.7 74.7 C 32.1 76.2 31.5 77.6 30.9 79.0 C 30.2 80.5 29.6 81.9 29.0 83.3 C 28.4 84.7 27.7 86.2 27.2 87.6 C 26.6 89.0 26.1 90.5 25.6 91.9 C 25.0 93.3 24.5 94.7 24.0 96.2 C 23.4 97.6 22.9 99.0 22.4 100.5 C 21.8 101.9 21.3 103.3 20.8 104.8 C 20.3 106.2 19.9 107.6 19.5 109.0 C 19.0 110.5 18.6 111.9 18.1 113.3 C 17.7 114.8 17.2 116.2 16.8 117.6 C 16.4 119.1 15.9 120.5 15.5 122.0 C 15.1 123.5 14.8 125.0 14.5 126.5 C 14.1 128.0 13.7 129.6 13.4 131.1 C 13.0 132.6 12.7 134.1 12.3 135.6 C 11.9 137.2 11.6 138.7 11.2 140.2 C 10.9 141.7 10.5 143.2 10.2 144.7 C 9.8 146.3 9.5 147.8 9.2 149.3 C 8.9 150.8 8.6 152.3 8.4 153.9 C 8.1 155.4 7.9 156.9 7.6 158.5 C 7.4 160.0 7.2 161.7 6.9 163.2 C 6.7 164.8 6.3 166.3 6.1 167.9 C 5.9 169.4 5.9 171.1 5.7 172.6 C 5.5 174.2 5.2 175.7 5.0 177.2 C 4.8 178.8 4.8 180.5 4.7 182.1 C 4.5 183.7 4.3 185.3 4.3 186.9 C 4.2 188.5 4.2 190.1 4.2 191.7 C 4.2 193.3 4.0 194.9 4.0 196.5 C 4.0 198.1 4.0 199.7 4.0 201.4 C 4.0 203.0 4.0 204.6 4.1 206.2 C 4.1 207.8 4.3 209.4 4.4 211.0 C 4.5 212.6 4.7 214.2 4.9 215.8 C 5.0 217.4 5.1 219.0 5.3 220.6 C 5.5 222.1 5.8 223.6 6.0 225.2 C 6.2 226.8 6.4 228.4 6.6 230.0 C 6.9 231.5 7.1 233.0 7.5 234.5 C 7.8 236.0 8.2 237.5 8.7 239.0 C 9.2 240.5 9.7 241.9 10.4 243.3 C 11.0 244.7 11.6 246.1 12.4 247.4 C 13.2 248.7 14.2 249.9 15.2 251.1 C 16.2 252.3 17.2 253.5 18.3 254.6 C 19.5 255.7 20.8 257.0 22.2 257.8 C 23.5 258.7 24.8 259.4 26.3 259.8 C 27.8 260.3 29.4 260.3 30.9 260.6 C 32.5 260.8 34.1 261.0 35.7 261.2 C 37.2 261.4 38.7 261.7 40.3 261.9 C 41.9 262.1 43.5 262.4 45.1 262.5 C 46.6 262.6 48.1 263.0 49.5 262.5 C 50.8 262.0 52.1 260.9 53.1 259.7 C 54.1 258.6 54.7 257.0 55.4 255.6 C 56.2 254.2 56.9 252.8 57.5 251.3 C 58.2 249.9 58.7 248.5 59.3 247.0 C 59.9 245.6 60.5 244.2 61.1 242.8 C 61.7 241.3 62.5 239.9 63.1 238.5 C 63.7 237.0 64.2 235.6 64.7 234.2 C 65.2 232.7 65.8 231.3 66.3 229.9 C 66.8 228.5 67.4 227.0 67.9 225.6 C 68.4 224.2 69.0 222.7 69.5 221.3 C 70.1 219.9 70.6 218.5 71.1 217.0 C 71.7 215.6 72.2 214.2 72.8 212.7 C 73.4 211.3 74.0 209.9 74.5 208.5 C 75.1 207.0 75.4 205.6 76.1 204.2 C 76.7 202.7 77.5 201.3 78.4 199.9 C 79.2 198.6 80.2 197.3 81.2 196.1 C 82.2 194.9 83.3 193.7 84.5 192.7 C 85.6 191.7 86.8 190.7 88.1 189.9 C 89.4 189.0 90.8 188.3 92.2 187.6 C 93.6 187.0 95.0 186.4 96.5 186.0 C 98.0 185.6 99.6 185.5 101.1 185.4 C 102.7 185.3 104.3 185.4 105.9 185.6 C 107.4 185.8 108.9 186.2 110.4 186.4 C 112.0 186.6 113.5 186.9 115.1 187.0 C 116.6 187.1 118.3 187.0 119.9 187.0 C 121.5 187.0 123.1 187.0 124.7 187.0 C 126.3 187.0 127.9 187.0 129.5 187.0 C 131.1 187.0 132.8 187.0 134.4 187.0 C 136.0 187.0 137.6 187.0 139.2 187.0 C 140.8 187.0 142.4 187.0 144.0 187.0 C 145.6 187.0 147.2 187.0 148.8 187.0 C 150.4 187.0 152.0 187.0 153.7 187.0 C 155.3 187.0 156.9 187.0 158.5 187.0 C 160.1 187.0 161.6 187.0 163.3 187.0 C 165.0 187.0 166.6 187.0 168.5 187.0 C 170.3 187.0 172.5 187.0 174.3 187.0 C 176.1 187.0 177.5 187.0 179.1 187.0 C 180.7 187.0 182.3 187.0 183.9 187.0 C 185.5 187.0 187.2 187.0 188.8 187.0 C 190.4 187.0 192.0 187.0 193.6 187.0 C 195.2 187.0 196.8 187.0 198.4 187.0 C 200.0 187.0 201.6 187.0 203.2 187.0 C 204.8 187.0 206.4 187.0 208.1 187.0 C 209.7 187.0 211.3 187.0 212.9 187.0 C 214.5 187.0 216.1 187.0 217.7 187.0 C 219.3 187.0 220.9 187.1 222.5 187.0 C 224.1 187.0 225.7 187.0 227.3 186.8 C 228.8 186.6 230.3 186.2 231.8 186.0 C 233.4 185.8 234.9 185.5 236.5 185.4 C 238.0 185.3 239.7 185.4 241.2 185.6 C 242.8 185.8 244.2 186.2 245.7 186.7 C 247.2 187.2 248.6 187.9 249.9 188.7 C 251.3 189.5 252.6 190.3 253.8 191.2 C 255.0 192.2 256.1 193.2 257.2 194.3 C 258.3 195.4 259.4 196.7 260.3 197.9 C 261.2 199.2 262.1 200.6 262.8 202.0 C 263.6 203.4 264.2 204.9 264.8 206.3 C 265.4 207.7 265.7 209.2 266.3 210.6 C 266.8 212.0 267.5 213.5 268.1 214.9 C 268.6 216.3 269.1 217.7 269.7 219.2 C 270.2 220.6 270.8 222.0 271.3 223.5 C 271.8 224.9 272.4 226.3 272.9 227.7 C 273.4 229.2 274.0 230.6 274.5 232.0 C 275.0 233.5 275.6 234.9 276.1 236.3 C 276.7 237.8 277.2 239.2 277.9 240.6 C 278.5 242.0 279.3 243.5 279.9 244.9 C 280.5 246.3 280.9 247.8 281.5 249.2 C 282.1 250.6 282.8 252.1 283.5 253.5 C 284.2 254.9 284.9 256.4 285.7 257.7 C 286.5 259.0 287.3 260.4 288.5 261.3 C 289.7 262.2 291.2 262.8 292.7 262.9 C 294.1 263.1 295.7 262.4 297.3 262.2 C 298.8 262.0 300.5 261.8 302.0 261.6 C 303.6 261.4 305.1 261.1 306.7 260.8 C 308.2 260.6 309.9 260.5 311.4 260.2 C 312.9 259.9 314.4 259.7 315.8 259.0 C 317.2 258.4 318.5 257.4 319.8 256.4 C 321.0 255.3 322.3 254.0 323.3 252.9 C 324.4 251.7 325.3 250.6 326.2 249.3 C 327.1 248.1 328.0 246.8 328.7 245.4 C 329.4 244.1 330.0 242.6 330.5 241.1 C 331.1 239.7 331.6 238.3 332.0 236.8 C 332.4 235.3 332.7 233.8 333.0 232.2 C 333.3 230.7 333.5 229.2 333.7 227.6 C 333.9 226.0 334.1 224.4 334.3 222.9 C 334.5 221.3 334.8 219.8 335.0 218.2 C 335.2 216.7 335.2 215.0 335.3 213.4 C 335.5 211.8 335.7 210.2 335.8 208.6 C 335.9 207.0 336.0 205.4 336.0 203.8 C 336.0 202.2 336.0 200.5 336.0 198.9 C 336.0 197.3 336.0 195.7 335.9 194.1 C 335.9 192.5 335.8 190.9 335.7 189.3 C 335.7 187.7 335.7 186.1 335.6 184.5 C 335.5 182.9 335.3 181.2 335.1 179.6 C 335.0 178.1 334.9 176.5 334.7 174.9 C 334.6 173.3 334.2 171.8 334.1 170.3 C 333.9 168.7 333.8 167.1 333.6 165.5 C 333.4 163.9 332.9 162.5 332.7 160.9 C 332.4 159.3 332.3 157.7 332.1 156.1 C 331.8 154.6 331.5 153.1 331.2 151.6 C 331.0 150.1 330.7 148.5 330.4 147.0 C 330.1 145.5 329.7 144.0 329.3 142.5 C 328.9 140.9 328.6 139.4 328.2 137.9 C 327.9 136.4 327.5 134.9 327.2 133.4 C 326.8 131.8 326.4 130.3 326.1 128.8 C 325.7 127.3 325.4 125.8 325.0 124.2 C 324.6 122.7 324.3 121.2 323.9 119.8 C 323.5 118.3 323.0 116.9 322.5 115.5 C 322.1 114.0 321.6 112.6 321.2 111.2 C 320.8 109.8 320.3 108.3 319.9 106.9 C 319.4 105.5 319.0 104.0 318.5 102.6 C 317.9 101.2 317.4 99.8 316.8 98.3 C 316.3 96.9 315.8 95.5 315.2 94.0 C 314.7 92.6 314.2 91.2 313.6 89.7 C 313.1 88.3 312.5 86.9 312.0 85.5 C 311.4 84.0 310.7 82.6 310.1 81.2 C 309.5 79.7 308.8 78.3 308.2 76.9 C 307.6 75.5 307.0 74.0 306.3 72.6 C 305.7 71.2 305.1 69.8 304.4 68.4 C 303.7 67.0 303.0 65.6 302.2 64.4 C 301.3 63.1 300.4 61.9 299.4 60.9 C 298.4 59.9 296.9 59.5 296.1 58.3 C 295.4 57.2 295.5 55.3 294.7 54.1 C 293.8 52.9 292.3 52.0 291.1 51.1 C 289.8 50.2 288.4 49.5 287.0 48.8 C 285.6 48.1 284.1 47.6 282.7 47.0 C 281.2 46.5 279.8 46.0 278.3 45.5 C 276.8 45.1 275.3 44.8 273.8 44.5 C 272.2 44.1 270.7 43.8 269.1 43.7 C 267.6 43.5 265.9 43.6 264.3 43.7 C 262.7 43.7 261.1 43.6 259.5 43.8 C 257.9 44.0 256.2 44.1 254.9 44.7 C 253.6 45.2 252.5 46.2 251.7 47.3 C 250.9 48.4 251.2 50.4 250.2 51.2 C 249.2 52.0 247.2 52.0 245.6 52.0 C 244.1 51.9 242.6 51.3 241.0 51.0 C 239.4 50.8 237.8 50.7 236.2 50.5 C 234.6 50.3 233.0 50.1 231.4 49.8 C 229.9 49.6 228.4 49.2 226.8 49.0 C 225.2 48.7 223.6 48.7 222.1 48.5 C 220.5 48.4 219.0 48.0 217.4 47.9 C 215.9 47.7 214.2 47.7 212.6 47.5 C 211.0 47.4 209.4 47.2 207.8 47.1 C 206.2 47.0 204.6 46.9 203.0 46.9 C 201.4 46.8 199.7 46.9 198.1 46.8 C 196.5 46.8 194.9 46.6 193.3 46.5 C 191.7 46.4 190.1 46.4 188.5 46.3 C 186.9 46.2 185.3 46.1 183.7 46.0 C 182.1 45.9 180.5 45.8 178.8 45.8 C 177.2 45.8 175.5 45.8 174.0 45.8 C 172.6 45.8 171.1 45.8 170.2 45.8 C 169.3 45.8 169.5 45.8 168.4 45.8 Z"
  readonly property string triggerPath: "M 64.2 4.0 C 64.8 4.0 65.9 4.0 66.8 4.2 C 67.6 4.4 68.4 4.7 69.2 5.0 C 70.0 5.3 70.8 5.6 71.5 6.0 C 72.3 6.5 73.0 7.1 73.7 7.7 C 74.4 8.3 75.1 8.9 75.6 9.6 C 76.2 10.3 76.5 11.1 77.0 11.8 C 77.4 12.6 77.8 13.5 78.2 14.3 C 78.5 15.2 78.7 16.1 78.8 17.0 C 79.0 17.9 79.0 18.8 79.1 19.7 C 79.2 20.6 79.3 21.5 79.4 22.4 C 79.6 23.2 79.8 24.1 79.9 25.0 C 80.0 25.9 80.1 26.8 80.2 27.7 C 80.4 28.6 80.6 29.5 80.7 30.4 C 80.8 31.3 81.0 32.2 81.0 33.1 C 81.0 33.9 81.1 34.9 80.8 35.6 C 80.4 36.2 79.6 36.7 78.9 37.0 C 78.1 37.3 77.1 37.3 76.3 37.4 C 75.4 37.6 74.7 37.9 73.8 38.0 C 72.9 38.2 72.0 38.1 71.1 38.2 C 70.2 38.3 69.3 38.5 68.4 38.7 C 67.6 38.9 66.7 39.1 65.8 39.2 C 64.9 39.4 64.0 39.6 63.1 39.8 C 62.2 40.0 61.3 40.1 60.4 40.3 C 59.5 40.5 58.6 40.7 57.7 40.8 C 56.8 41.0 55.9 41.2 55.0 41.3 C 54.2 41.5 53.3 41.5 52.4 41.7 C 51.5 41.9 50.5 42.3 49.7 42.4 C 48.8 42.5 47.9 42.8 47.2 42.4 C 46.6 41.9 46.0 40.7 45.8 39.8 C 45.6 38.9 45.8 38.0 45.8 37.1 C 45.8 36.2 45.8 35.3 45.8 34.4 C 45.8 33.5 45.9 32.6 46.0 31.7 C 46.1 30.8 46.3 29.9 46.5 29.1 C 46.6 28.2 46.6 27.2 46.8 26.4 C 47.0 25.5 47.3 24.7 47.5 23.9 C 47.7 23.0 47.7 22.1 47.9 21.3 C 48.1 20.4 48.3 19.6 48.5 18.8 C 48.8 18.0 49.2 17.2 49.6 16.4 C 49.9 15.6 50.2 14.8 50.6 14.0 C 51.0 13.2 51.4 12.3 51.9 11.6 C 52.4 10.8 52.8 10.1 53.4 9.4 C 54.0 8.7 54.8 8.0 55.4 7.4 C 56.1 6.8 56.8 6.2 57.6 5.7 C 58.4 5.3 59.3 5.0 60.1 4.7 C 61.0 4.5 62.1 4.3 62.8 4.1 C 63.5 4.0 63.5 4.0 64.2 4.0 Z"
  readonly property string bumperPath: "M 42.7 60.5 C 43.5 55 47 51.5 51 49.9 C 57 47 63 44.8 68.5 43.9 "
    + "C 73 43.5 79 43.5 82.9 44.1 C 86.5 44.6 88.5 46.5 88.5 49.7 L 88.5 51.8 C 74 52.5 56 55.5 42.7 60.5 Z"
  readonly property string corePath: "M 109.6 104.8 L 230.4 104.8 C 240 120 252 136 254.5 147.6 "
    + "C 258 158 261 164 262.6 169.1 C 268 182 274 196 276 203.9 C 284 226 296 246 306 264 "
    + "L 34 264 C 44 246 56 226 64 203.9 C 66 196 72 182 77.4 169.1 C 79 164 82 158 85.5 147.6 "
    + "C 88 136 100 120 109.6 104.8 Z"
  readonly property string touchpadPath: "M 106.5 53 Q 170 45 233.5 53 L 228 101 Q 226 112 215 114 "
    + "Q 170 119 125 114 Q 114 112 112 101 Z"
  readonly property string lightBarPath: "M 103 56 L 107.5 99 Q 109.5 112 119 116 M 237 56 L 232.5 99 Q 230.5 112 221 116"

  component Mirrored: Shape {
    id: m
    property bool mirrored
    width: 340; height: 268
    preferredRendererType: Shape.CurveRenderer
    transform: Scale { xScale: m.mirrored ? -1 : 1; origin.x: 170 }
  }

  // ── Triggers: press down and fill as they're pulled ────────────────────
  Repeater {
    model: [{ mirrored: false, axis: "lt", btn: "l2" }, { mirrored: true, axis: "rt", btn: "r2" }]
    delegate: Item {
      id: trig
      required property var modelData
      readonly property real pull: ds.pull(modelData.axis, modelData.btn)
      width: 340; height: 268
      transform: [
        Translate { y: -3 }, // a little air between trigger and bumper
        Scale { origin.y: 39; yScale: 1 - 0.35 * trig.pull }
      ]

      Mirrored {
        mirrored: trig.modelData.mirrored
        ShapePath {
          strokeColor: trig.pull > 0 ? ds.glow : ds.edge
          strokeWidth: 1
          fillGradient: LinearGradient {
            x1: 0; y1: 4; x2: 0; y2: 42
            GradientStop { position: 0; color: "#4a4d55" }
            GradientStop { position: 0.55; color: "#1d1e22" }
            GradientStop { position: 1; color: "#0c0c0e" }
          }
          PathSvg { path: ds.triggerPath }
        }
      }
      Item { // blue fill rising from the bottom with the pull
        y: 43 - 40 * trig.pull
        width: 340; height: 40 * trig.pull
        clip: true
        Mirrored {
          y: -parent.y
          mirrored: trig.modelData.mirrored
          ShapePath {
            strokeColor: "transparent"
            fillColor: Qt.rgba(0.24, 0.48, 1, 0.85)
            PathSvg { path: ds.triggerPath }
          }
        }
      }
    }
  }

  // ── Shell ──────────────────────────────────────────────────────────────
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeColor: ds.edge
      strokeWidth: 1
      fillGradient: LinearGradient {
        x1: 0; y1: 44; x2: 0; y2: 265
        GradientStop { position: 0; color: "#222327" }
        GradientStop { position: 0.5; color: "#151618" }
        GradientStop { position: 1; color: "#0b0b0d" }
      }
      PathSvg { path: ds.bodyPath }
    }
  }

  // Shape of the shell, used to clip the core and the edge sheen.
  Shape {
    id: bodyMask
    anchors.fill: parent
    visible: false
    layer.enabled: true
    layer.textureSize: Qt.size(width * ds.detail, height * ds.detail)
    preferredRendererType: Shape.CurveRenderer
    ShapePath { fillColor: "white"; strokeColor: "transparent"; PathSvg { path: ds.bodyPath } }
  }

  Item {
    anchors.fill: parent
    layer.enabled: true
    layer.textureSize: Qt.size(width * ds.detail, height * ds.detail)
    layer.effect: MultiEffect {
      maskEnabled: true
      maskSource: bodyMask
      maskThresholdMin: 0.5
      maskSpreadAtMin: 1
    }

    Shape {
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer
      ShapePath { // light catching the outer edges of the wings
        fillColor: "transparent"
        strokeColor: Qt.rgba(1, 1, 1, 0.07)
        strokeWidth: 9
        PathSvg { path: ds.bodyPath }
      }
      ShapePath { // core, with the seams down the inner grips
        strokeColor: "#2b303b"
        strokeWidth: 1
        fillGradient: LinearGradient {
          x1: 0; y1: 104; x2: 0; y2: 262
          GradientStop { position: 0; color: "#232833" }
          GradientStop { position: 0.4; color: "#1a1e27" }
          GradientStop { position: 1; color: "#2a3040" }
        }
        PathSvg { path: ds.corePath }
      }
    }
  }

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath { // touchpad
      strokeColor: "#2e3138"
      strokeWidth: 1
      fillGradient: LinearGradient {
        x1: 0; y1: 46; x2: 0; y2: 118
        GradientStop { position: 0; color: "#2a2c31" }
        GradientStop { position: 0.85; color: "#1a1b1f" }
        GradientStop { position: 1; color: "#2f323a" }
      }
      PathSvg { path: ds.touchpadPath }
    }
    ShapePath { // light bar glow
      fillColor: "transparent"
      strokeColor: Qt.rgba(0.24, 0.48, 1, 0.3)
      strokeWidth: 4.5
      capStyle: ShapePath.RoundCap
      PathSvg { path: ds.lightBarPath }
    }
    ShapePath { // light bar
      fillColor: "transparent"
      strokeColor: "#4d86ff"
      strokeWidth: 1.6
      capStyle: ShapePath.RoundCap
      PathSvg { path: ds.lightBarPath }
    }
  }

  // ── Bumpers ────────────────────────────────────────────────────────────
  Repeater {
    model: [{ mirrored: false, btn: "l1" }, { mirrored: true, btn: "r1" }]
    delegate: Mirrored {
      id: bumper
      required property var modelData
      readonly property bool down: ds.b(modelData.btn)
      mirrored: modelData.mirrored
      ShapePath {
        strokeColor: bumper.down ? ds.glow : ds.edge
        strokeWidth: 1
        fillGradient: LinearGradient {
          x1: 0; y1: 43; x2: 0; y2: 60
          GradientStop { position: 0; color: bumper.down ? "#6d9bff" : "#585b63" }
          GradientStop { position: 0.3; color: bumper.down ? ds.glow : "#1c1d21" }
          GradientStop { position: 1; color: bumper.down ? "#2a5ad8" : "#0e0e10" }
        }
        PathSvg { path: ds.bumperPath }
      }
    }
  }

  // Player light under the touchpad
  Rectangle {
    x: 170 - 14; y: 118.5
    width: 28; height: 6; radius: 3
    color: Qt.rgba(1, 1, 1, 0.08)
  }
  Rectangle {
    x: 170 - 8; y: 120
    width: 16; height: 2.6; radius: 1.3
    color: Qt.rgba(1, 1, 1, 0.6)
  }

  // Create / Options
  Repeater {
    model: [{ n: "select", x: 92.2, r: -15 }, { n: "start", x: 247.8, r: 15 }]
    delegate: Rectangle {
      id: pill
      required property var modelData
      x: modelData.x - 4; y: 71.3 - 6
      width: 8; height: 12; radius: 4
      rotation: modelData.r
      border.width: 1
      border.color: ds.b(modelData.n) ? ds.glow : "#43464d"
      gradient: Gradient {
        GradientStop { position: 0; color: ds.b(pill.modelData.n) ? "#6d9bff" : "#2a2c31" }
        GradientStop { position: 1; color: ds.b(pill.modelData.n) ? "#2a5ad8" : "#0c0c0e" }
      }
    }
  }

  // ── D-pad ──────────────────────────────────────────────────────────────
  Repeater {
    model: [{ n: "up", r: 0 }, { n: "right", r: 90 }, { n: "down", r: 180 }, { n: "left", r: 270 }]
    delegate: Item {
      id: arrow
      required property var modelData
      readonly property bool down: ds.b(modelData.n)
      x: 66.4 - 40; y: 107.2 - 40
      width: 80; height: 80
      rotation: modelData.r
      Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
          strokeColor: arrow.down ? ds.glow : "#4a4d55"
          strokeWidth: 1
          joinStyle: ShapePath.RoundJoin
          fillGradient: LinearGradient {
            x1: 0; y1: 7; x2: 0; y2: 35
            GradientStop { position: 0; color: arrow.down ? "#6d9bff" : "#303238" }
            GradientStop { position: 0.35; color: arrow.down ? ds.glow : "#131416" }
            GradientStop { position: 1; color: arrow.down ? "#2a5ad8" : "#08080a" }
          }
          PathSvg { path: "M 31 11 Q 31 7 35 7 L 45 7 Q 49 7 49 11 L 49 27 L 40 35 L 31 27 Z" }
        }
        ShapePath {
          fillColor: ds.symbol
          strokeColor: "transparent"
          PathSvg { path: "M 40 13.3 L 42.7 17.6 L 37.3 17.6 Z" }
        }
      }
    }
  }

  // ── Face buttons ───────────────────────────────────────────────────────
  Repeater {
    model: [
      { n: "north", dx: 0, dy: -24.7, c: "#3ddc97", p: "M 12 6 L 17.3 15.3 L 6.7 15.3 Z" },
      { n: "east", dx: 24.7, dy: 0, c: "#ff6b6b", p: "M 12 6.3 A 5.7 5.7 0 1 1 12 17.7 A 5.7 5.7 0 1 1 12 6.3 Z" },
      { n: "south", dx: 0, dy: 24.7, c: "#6f9bff", p: "M 7.4 7.4 L 16.6 16.6 M 16.6 7.4 L 7.4 16.6" },
      { n: "west", dx: -24.7, dy: 0, c: "#e78bd8", p: "M 7 7 L 17 7 L 17 17 L 7 17 Z" }
    ]
    delegate: Rectangle {
      id: faceBtn
      required property var modelData
      readonly property bool down: ds.b(modelData.n)
      x: 273.3 + modelData.dx - 12; y: 107.2 + modelData.dy - 12
      width: 24; height: 24; radius: 12
      border.width: 1
      border.color: down ? modelData.c : "#4a4d55"
      gradient: Gradient {
        GradientStop { position: 0; color: faceBtn.down ? Qt.lighter(faceBtn.modelData.c, 1.25) : "#2e3035" }
        GradientStop { position: 0.45; color: faceBtn.down ? faceBtn.modelData.c : "#111214" }
        GradientStop { position: 1; color: faceBtn.down ? Qt.darker(faceBtn.modelData.c, 1.3) : "#070708" }
      }
      Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
          fillColor: "transparent"
          strokeColor: faceBtn.down ? "white" : ds.symbol
          strokeWidth: 1.4
          capStyle: ShapePath.RoundCap
          joinStyle: ShapePath.RoundJoin
          PathSvg { path: faceBtn.modelData.p }
        }
      }
    }
  }

  // ── Sticks ─────────────────────────────────────────────────────────────
  Repeater {
    model: [{ x: 115.5, ax: "lx", ay: "ly", btn: "l3" }, { x: 223.7, ax: "rx", ay: "ry", btn: "r3" }]
    delegate: Item {
      id: stick
      required property var modelData
      readonly property real sx: ds.a(modelData.ax)
      readonly property real sy: ds.a(modelData.ay)
      readonly property bool moved: Math.abs(sx) + Math.abs(sy) > 0.15
      readonly property bool down: ds.b(modelData.btn)
      x: modelData.x - 21; y: 152.4 - 21
      width: 42; height: 42
      Rectangle { // well
        anchors.fill: parent
        radius: 21
        border.width: 1
        border.color: "#2c3039"
        gradient: Gradient {
          GradientStop { position: 0; color: "#050506" }
          GradientStop { position: 1; color: "#1c2029" }
        }
      }
      Rectangle { // cap
        width: 32; height: 32; radius: 16
        x: 5 + stick.sx * 6
        y: 5 + stick.sy * 6
        border.width: 1
        border.color: stick.moved ? ds.glow : "#2e3036"
        gradient: Gradient {
          GradientStop { position: 0; color: stick.down ? "#6d9bff" : "#2a2c31" }
          GradientStop { position: 1; color: stick.down ? "#2a5ad8" : "#0b0b0d" }
        }
        Rectangle { // white ring
          anchors.centerIn: parent
          width: 20.5; height: 20.5; radius: 10.25
          color: "#0c0c0e"
          border.width: 1.6
          border.color: stick.moved ? ds.glow : "#e3e5ea"
        }
      }
    }
  }

  // Speaker grille, PS logo, mic mute
  Column {
    x: 170 - width / 2; y: 126.5
    spacing: 2
    Repeater {
      model: [5, 4]
      delegate: Row {
        required property int modelData
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 2.4
        Repeater {
          model: parent.modelData
          delegate: Rectangle { width: 2; height: 2; radius: 1; color: "#050608"; border.width: 0.5; border.color: "#2c303a" }
        }
      }
    }
  }
  Text {
    x: 170 - width / 2; y: 151.6 - height / 2
    text: "󰐔" // nf-md-sony_playstation
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 15
    color: ds.b("home") ? ds.glow : "#5d6370"
  }
  Rectangle {
    x: 170 - 7; y: 168
    width: 14; height: 3.5; radius: 1.75
    color: "#0c0d10"
    border.width: 0.8
    border.color: "#3a3e48"
  }
  Rectangle {
    x: 169; y: 174
    width: 2; height: 2; radius: 1
    color: "#3a3e48"
  }
}
