# DOCX 审阅标记的 Open XML 参考

DOCX 是 ZIP 包。正文通常位于 `word/document.xml`，但修订也可能出现在 `word/header*.xml`、`word/footer*.xml`、`word/footnotes.xml` 和 `word/endnotes.xml`。修改时保留各部件的关系和未涉及的 XML。

## 修订元素

最常见的文字修订形态如下（命名空间前缀可不同，但 URI 必须相同）：

```xml
<w:ins w:id="12" w:author="修改人" w:date="2026-10-17T02:18:31Z">
  <w:r><w:rPr>...</w:rPr><w:t>新增文字</w:t></w:r>
</w:ins>
<w:del w:id="13" w:author="修改人" w:date="2026-10-17T02:18:40Z">
  <w:r><w:rPr>...</w:rPr><w:delText>删除文字</w:delText></w:r>
</w:del>
```

删除文本不能用 `w:t` 代替 `w:delText`。插入和删除包里的运行属性应尽量复制原运行的 `w:rPr`，以便接受修订后仍保持原来的字号、字体、上下标和语言设置。

字段、书签、超链接、数学对象和编号有自己的合法嵌套位置。不要把半个字段或半个书签随意包进 `w:ins`/`w:del`；遇到复杂结构时优先让 Word 自动化完成操作，或停下来请求人工处理。

## ID、作者和时间

扫描所有相关 XML 部件中的 `w:ins`、`w:del`、`w:moveFrom`、`w:moveTo`、`w:rPrChange`、`w:pPrChange` 等元素，取现有 `w:id` 的最大值后递增。批注 ID 来自 `comments.xml` 的 `w:comment/@w:id`，不要与既有值冲突。修订作者使用用户明确提供的姓名；时间使用 UTC 的 `YYYY-MM-DDTHH:MM:SSZ` 格式。

## 跟踪修订设置

`word/settings.xml` 应包含：

```xml
<w:trackRevisions/>
```

如果已有 `w:trackRevisions w:val="1"`，保留其形式也可以。不要删除与修订显示有关的设置，也不要在不必要时改动文档保护。

## 批注

批注正文位于 `word/comments.xml`，正文中的 `w:commentRangeStart`、`w:commentRangeEnd` 和 `w:commentReference` 需要匹配同一个批注 ID；相关部件必须在 `[Content_Types].xml` 和关系文件中保持正确。若要添加批注，优先调用 Word 自动化接口；直接写包时必须同时维护这些关系。

## 安全写包

写回 ZIP 时应使用临时文件，然后原子替换输出文件；不要在原 ZIP 上就地覆盖。保持 XML 声明、UTF-8 编码、压缩包中的其他部件和时间戳（除非工具不可避免地重写）。写回后重新打开 ZIP，并对所有修改过的 XML 做解析检查。

## 常见错误

- 用红字、删除线或高亮模拟修订，导致审阅窗格看不到真正的新增/删除。
- 只更新 `lastModifiedBy`，却没有在修订元素上写 `w:author`。
- 重置 `w:id`，造成 Word 修订或批注 ID 冲突。
- 删除旧的修订后再写新文本，破坏用户原有的审阅历史。
- 把替换操作写成一整段 `w:ins`，让读者无法看到具体删除了什么。
- 重新生成文档时丢失 Zotero/域代码、页眉页脚、编号、批注或自定义 XML。
