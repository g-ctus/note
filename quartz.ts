import { loadQuartzConfig, loadQuartzLayout } from "./quartz/plugins/loader/config-loader"
import * as ExternalPlugin from "./.quartz/plugins"

// Sort explorer by date tag (newest first), falling back to alphabetical
ExternalPlugin.Explorer({
  sortFn: (a, b) => {
    // folders first
    if (a.isFolder && !b.isFolder) return -1
    if (!a.isFolder && b.isFolder) return 1

    // Extract date from tags (format: YYYY/MM/DD or YYYY/MM)
    const datePattern = /^\d{4}\/\d{2}(\/\d{2})?$/
    const getDate = (node: any): string => {
      const tags: string[] = node.data?.tags ?? []
      const dateTags = tags.filter((t: string) => datePattern.test(t)).sort()
      return dateTags.length > 0 ? dateTags[dateTags.length - 1] : ""
    }

    const dateA = getDate(a)
    const dateB = getDate(b)

    // Both have dates: newest first
    if (dateA && dateB) return dateB.localeCompare(dateA)
    // Only one has date: dated items first
    if (dateA && !dateB) return -1
    if (!dateA && dateB) return 1
    // Neither has date: alphabetical
    return a.displayName.localeCompare(b.displayName, undefined, {
      numeric: true,
      sensitivity: "base",
    })
  },
})

const config = await loadQuartzConfig()
export default config
export const layout = await loadQuartzLayout()
