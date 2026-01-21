# JSON Data Structure Reference
**File**: `assets/data/output.optimized_src.json`

This file contains the main database of shows, sources, and tracks for the application. It uses a minified structure to save space.

## Root Object
List of `Show` objects.

## Show Object
| Key | Type | Description |
| :--- | :--- | :--- |
| `date` | String | Date of the show in `YYYY-MM-DD` format. |
| `name` | String | Name of the venue/show. |
| `l` | String | Location (City, State/Country). |
| `sources` | List | List of `Source` objects available for this show. |

## Source Object
| Key | Type | Description |
| :--- | :--- | :--- |
| `id` | String | The unique ID (shnid) of the source (e.g., "131169"). |
| `src` | String | Source type description (e.g., "SBD", "AUD"). |
| `sets` | List | List of `Set` objects. |
| `_d` | String | (Optional) Source description/metadata. |

## Set Object
| Key | Type | Description |
| :--- | :--- | :--- |
| `n` | String | Set name (e.g., "Set 1", "Set 2", "Encore"). |
| `t` | List | List of `Track` objects. |

## Track Object
| Key | Type | Description |
| :--- | :--- | :--- |
| `n` | Integer | Track number/index in the set. |
| `t` | String | Track title. |
| `u` | String | Track filename/URL (relative to source base). |
| `d` | Integer | Duration in seconds. |

## Example
```json
{
  "date": "1973-06-09",
  "name": "RFK Stadium",
  "l": "Washington, DC",
  "sources": [
    {
      "id": "131169",
      "src": "SBD",
      "sets": [
        {
          "n": "Set 1",
          "t": [
            {
              "n": 1,
              "t": "Promised Land",
              "u": "gd73-06-09s1t01.mp3",
              "d": 219
            }
          ]
        }
      ]
    }
  ]
}
```
