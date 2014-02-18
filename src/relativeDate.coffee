angular.module('relativeDate',[]).factory 'relativeDate', [ 'dateFilter', '$interval', (dateFilter, $interval) ->
  @time_ago = (time, format) ->
    date = new Date((time || "").replace(/-/g,"/").replace(/[TZ]/g," "))
    diff = (((new Date()).getTime() - date.getTime() + ( date.getTimezoneOffset() * 60 * 1000 )) / 1000)
    day_diff = Math.floor(diff / 86400)
    if ( isNaN(day_diff) || day_diff < 0 || day_diff >= 22 ) # if older than 3 weeks (21 days) don't calculate a relative-time label
      return dateFilter(time, format) # instead, use angular's dateFilter to return an absolute timestamp formated with user provided 'fallbackFormat'

    return day_diff == 0 && (
      diff < 60 && "just now" ||
      diff < 120 && "about 1 minute ago" ||
      diff < 3600 && Math.floor( diff / 60 ) + " minutes ago" ||
      diff < 7200 && "about 1 hour ago" ||
      diff < 86400 && Math.floor( diff / 3600 ) + " hours ago") ||
      day_diff == 1 && "Yesterday" ||
      day_diff < 7 && day_diff + " days ago" ||
      day_diff == 7 && "a week ago" ||
      day_diff < 22 && Math.ceil( day_diff / 7 ) + " weeks ago"

  return {
    set: (date, fallbackFormat, callback) =>
      relDate = @time_ago(date, fallbackFormat)

      iterator = $interval =>
        relDate = @time_ago(date, fallbackFormat)
        callback(relDate)
      , 60000 # execute callback function every 60 seconds

      success = -> # success callback (not needed here) is called by the $interval promise when all iteration is complete - only possible if the optional 3rd arg (total iterations) was passed into $interval
        return
      error = ->   # error callback (not needed here) is called by the $interval promise if iteration is canceled early
        return
      notice = ->  # notice callback is called by the $interval promise after each iteration
        $interval.cancel(iterator) unless !!(relDate[-3..-1] is "now"|| relDate[-3..-1] is "ago"|| relDate[-3..-1] is "day")
        # kill $interval updates now if not using relative-time labels (older than 3 weeks)

      iterator.then(success, error, notice)

      callback(relDate) # initial call to callback function.
      return iterator   # return the promise object incase you plan on manualing canceling iteration at somepoint
  }
]