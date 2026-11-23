export const exportToCSV = (filename, data, columns) => {
  if (!data || !data.length) return;
  const headers = columns ? columns.map(c => c.label).join(",") : Object.keys(data[0]).join(",");
  const rows = data.map(item => {
    if (columns) {
      return columns.map(c => `"${String(item[c.key] ?? '').replace(/"/g, '""')}"`).join(",");
    }
    return Object.values(item).map(v => `"${String(v ?? '').replace(/"/g, '""')}"`).join(",");
  });
  const csvContent = "data:text/csv;charset=utf-8," + [headers, ...rows].join("\n");
  const link = document.createElement("a");
  link.href = encodeURI(csvContent);
  link.download = `${filename}_${Date.now()}.csv`;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
};

