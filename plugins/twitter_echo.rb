require 'hpricot'
require 'open-uri'
require 'ostruct'
require 'time'
require 'htmlentities'

# The workings of this plugin are based on http://github.com/paulca/twitter2campfire
# Thanks to Paul Campbell and Contrast! <http://www.contrast.ie/>

class TwitterEcho < PluginBase
  
  at_interval 2.minutes, :echo_tweets
  
  def initialize
    @feed   = Bot.instance.config['twitter_feed']
    @latest = Time.now
  end
  
  def echo_tweets(msg = nil)
    recent_tweets.reverse.each do |tweet|
      speak("#{coder.decode(tweet.from)}: #{coder.decode(tweet.text)} #{tweet.link}")
    end
    @latest = latest_tweet.date   # next time, only print tweets newer than this
    @doc    = nil                 # reset the feed so that next time we can actually any new tweets
  end
  
  protected
  
  def raw_feed
    @doc ||= Hpricot(open(@feed))
  end
  
  def all_tweets
    (raw_feed/'entry').map { |e| OpenStruct.new(
      :from => (e/'name').inner_html,
      :text => (e/'title').inner_html,
      :link => (e/'link').first['href'],
      :date => Time.parse((e/'published').inner_html)
    )}
  end
  
  def latest_tweet
    all_tweets.first
  end

  def recent_tweets
    all_tweets.reject { |e| e.date.to_i <= @latest.to_i }
  end
  
  def coder
    HTMLEntities.new
  end
end