---
name: word-review-editing
description: Edit .docx documents with Microsoft Word-style tracked changes, review metadata, and comments; ask for the modification author before making edits and preserve document structure and formatting.
metadata:
  short-description: Word tracked editing and review workflow
---

# Word 审阅式编辑

用于需要对 `.docx` 做规范编辑、校对、改写、增删或格式调整，并且希望在 Word 的“审阅”视图中清楚看到每一处修改的任务。目标交付物必须保留原文、把新增和删除作为真正的修订显示，并能追溯到修改人。

## 开始编辑前

1. 确认输入文件和输出文件。默认不覆盖原文件，输出为同目录下的副本；文件名可使用 `<原文件名>_修订_<修改人>.docx`，除非用户指定了名称。
2. 如果用户没有明确给出修改人，先只问：**“请提供此次 Word 修订显示的修改人姓名（会写入修订和批注作者字段）。”** 不要从文件名、系统账户或 `lastModifiedBy` 猜测，也不要用“作者”“用户”等占位词继续写入。
3. 读取文档包中的 `word/settings.xml`、主文档及其相关的页眉、页脚、脚注、尾注、批注部件，确认已有修订、批注和文档保护设置。保留现有修订，不先接受或拒绝它们。
4. 把需求拆成变更清单，每一项标记为：`新增`、`删除`、`替换`、`格式调整` 或 `批注建议`。替换必须能在审阅视图中看出“旧内容被删除、新内容被插入”，不能把整段重写成一团无法核对的新增文本。

## 记录修订的规则

- **新增**：用真正的 `w:ins` 修订包住新增的运行（`w:r`）；文字使用 `w:t`，需要保留空格时设置 `xml:space="preserve"`。
- **删除**：用真正的 `w:del` 包住被删除的运行；普通文字使用 `w:delText`，字段指令使用 `w:delInstrText`。不要只设置删除线、红色或字体颜色来伪造删除。
- **替换**：先记录删除，再记录相邻的新增；保留原有段落、字符样式、域、书签、超链接和编号结构，除非用户明确要求改变它们。
- **格式调整**：优先使用 Word 的跟踪格式修订（运行属性用 `w:rPrChange`，段落属性用 `w:pPrChange`），不要把纯格式变化伪装成文字增删。若工具无法可靠记录格式修订，保留原格式并用批注说明待人工处理。
- **批注建议**：使用独立的批注范围和 `comments.xml`，批注作者与修订作者都使用用户提供的修改人；不要把批注文字混入正文。
- 每个修订都必须写入 `w:id`、`w:author` 和 UTC 的 `w:date`。`w:id` 在整个文档包的修订范围内保持唯一，不能重置已有编号；批注编号也不能与已有批注冲突。
- 在 `word/settings.xml` 保留或启用 `<w:trackRevisions/>`，使 Word 打开文件时仍处于记录修订状态。不要删除已有的保护、兼容性和显示设置。
- `docProps/core.xml` 的 `cp:lastModifiedBy` 可以同步为修改人，但它不能替代修订元素上的 `w:author`；两者都要正确。

## 工具选择与操作边界

- 如果当前环境装有桌面版 Microsoft Word，优先用 Word 的自动化接口：设置 `TrackRevisions = True`、设置用户名称为修改人，再对 Range/Selection 执行插入、删除、替换和批注操作。这样由 Word 生成的修订最兼容其审阅界面。
- 如果没有 Word，按 [references/ooxml-review.md](references/ooxml-review.md) 直接操作 DOCX 的 Open XML 包。只修改必要的 XML 部件并保留 ZIP 包中的其他文件、关系和扩展属性；不要先转成纯文本、HTML 或重新生成一个丢失修订的文档。
- 编辑前后都应保存一份原文件副本。遇到加密、数字签名、文档保护、损坏的关系或无法判断的复杂域代码时，停止自动改写并报告原因。

## 交付前检查

1. 使用 Word 或 XML 检查器确认文件可以打开；没有未闭合的修订、重复的修订/批注 ID、失效的关系或丢失的部件。
2. 确认新增均显示为插入、删除均显示为删除；没有把修改后的整段误标为新增，也没有静默改变未列入变更清单的内容。
3. 确认每个修订和批注的作者都是用户指定的修改人，日期为有效 UTC 时间；`trackRevisions` 仍有效。
4. 运行 `scripts/validate_docx_review.ps1` 做结构性检查；如工具不可用，至少检查 `word/settings.xml`、主文档和所有含修订的部件。
5. 在回复中给出简短变更台账：新增几处、删除几处、替换几处、格式调整几处、批注几条，并指出输出文件路径。不要声称已完成 Word 界面检查，除非确实打开验证过。

## 相关参考

- 需要直接读写 Open XML 修订、批注或字段时，读取 [references/ooxml-review.md](references/ooxml-review.md)。
- 需要快速核对 DOCX 是否保留审阅标记时，运行 [scripts/validate_docx_review.ps1](scripts/validate_docx_review.ps1)。
