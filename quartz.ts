import { loadQuartzConfig, loadQuartzLayout } from "./quartz/plugins/loader/config-loader"
import * as ExternalPlugin from "./.quartz/plugins"

// Sort explorer by created date (newest first)
// Date is injected as a tag "created/YYYY-MM-DD" by publish.sh
ExternalPlugin.Explorer({
  sortFn: (a, b) => {
    // folders first
    if (a.isFolder && !b.isFolder) return -1
    if (!a.isFolder && b.isFolder) return 1

    const getCreated = (node: any): string => {
      const tags: string[] = node.data?.tags ?? []
      const ct = tags.find((t: string) => t.startsWith("created/"))
      return ct ? ct.replace("created/", "") : ""
    }

    const dateA = getCreated(a)
    const dateB = getCreated(b)

    // Both have dates: newest first
    if (dateA && dateB) return dateB.localeCompare(dateA)
    // Only one has date: dated items first
    if (dateA && !dateB) return -1
    if (!dateA && dateB) return 1
    // Neither: alphabetical
    return a.displayName.localeCompare(b.displayName, undefined, {
      numeric: true,
      sensitivity: "base",
    })
  },
})

const config = await loadQuartzConfig()
export default config
export const layout = await loadQuartzLayout()
