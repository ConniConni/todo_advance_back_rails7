json.totalCount @report[:total_count]
json.countByStatus do
  json.notStarted @report[:count_by_status][:not_started]
  json.inProgress @report[:count_by_status][:in_progress]
  json.completed @report[:count_by_status][:completed]
end
json.completionRate @report[:completion_rate]
