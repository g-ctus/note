import { loadQuartzConfig, loadQuartzLayout } from "./quartz/plugins/loader/config-loader"
import * as ExternalPlugin from "./.quartz/plugins"

// Sort explorer by created date (newest first)
// Date is injected as a tag "created/YYYY-MM-DD" by publish.sh
ExternalPlugin.Explorer({
  useSavedState: false,
  sortFn: (a, b) => {
    // folders first
    if (a.isFolder && !b.isFolder) return -1
    if (!a.isFolder && b.isFolder) return 1

    // Extract created/ tag for date sorting
    let dateA = ""
    let dateB = ""
    try {
      const tagsA = (a.data && a.data.tags) || []
      const tagsB = (b.data && b.data.tags) || []
      for (const t of tagsA) {
        if (typeof t === "string" && t.startsWith("created/")) {
          dateA = t.slice(8)
          break
        }
      }
      for (const t of tagsB) {
        if (typeof t === "string" && t.startsWith("created/")) {
          dateB = t.slice(8)
          break
        }
      }
    } catch (e) {
      // fallback to alphabetical
    }

    if (dateA && dateB) return dateB < dateA ? -1 : dateB > dateA ? 1 : 0
    if (dateA) return -1
    if (dateB) return 1
    return a.displayName.localeCompare(b.displayName, undefined, {
      numeric: true,
      sensitivity: "base",
    })
  },
})

const config = await loadQuartzConfig()
export default config
export const layout = await loadQuartzLayout()
