class TopHits
  DEFAULT_PRE_TAG = '<strong>'
  DEFAULT_POST_TAG = '</strong>'
  TEXT_FIELDS = %w(title description caption)

  CUTOFF_FOR_DECAY = "now-6w/w"
  DECAY_SCALE = '4w'
  CUTOFF_BOOST_FACTOR = 0.119657286

  def initialize(query, size, from, flickr_groups, flickr_users, instagram_profiles, mrss_names)
    @query, @size, @from = query, size, from
    @flickr_groups, @flickr_users, @instagram_profiles, @mrss_names = flickr_groups, flickr_users, instagram_profiles, mrss_names
  end

  def query_body
    Jbuilder.encode do |json|
      filtered_query(json)
      aggs(json)
      suggest(json)
    end
  end

  def aggs(json)
    json.aggs do
      json.album_agg do
        albums(json)
        top_hits(json)
      end
    end
  end

  def top_hits(json)
    json.aggs do
      json.top_image_hits do
        json.top_hits do
          json.size 1
        end
      end
      json.top_score do
        json.max do
          json.script "_score"
        end
      end
    end
  end

  def albums(json)
    json.terms do
      json.field "album"
      json.order do
        json.top_score "desc"
      end
      json.size @from + @size + 1
    end
  end

  def suggest(json)
    json.suggest do
      json.text @query
      json.suggestion do
        phrase_suggestion(json)
      end
    end
  end

  def phrase_suggestion(json)
    json.phrase do
      json.analyzer 'bigram_analyzer'
      json.field 'bigram'
      json.size 1
      direct_generator(json)
      suggestion_highlight(json)
    end
  end

  def suggestion_highlight(json)
    json.highlight do
      json.pre_tag pre_tags.first
      json.post_tag post_tags.first
    end
  end

  def direct_generator(json)
    json.direct_generator do
      json.child! do
        json.field 'bigram'
        json.prefix_len 1
      end
    end
  end

  def filtered_query(json)
    json.query do
      json.function_score do
        json.functions do
          popularity_boost(json)
          recency_decay(json)
          older_photos(json)
        end
        json.query do
          json.filtered do
            filtered_query_query(json)
            filtered_query_filter(json)
          end
        end
      end
    end
  end

  def older_photos(json)
    json.child! do
      json.filter do
        json.range do
          json.taken_at do
            json.lt CUTOFF_FOR_DECAY
          end
        end
      end
      json.boost_factor CUTOFF_BOOST_FACTOR
    end
  end

  def recency_decay(json)
    json.child! do
      json.filter do
        json.range do
          json.taken_at do
            json.gte CUTOFF_FOR_DECAY
          end
        end
      end
      json.gauss do
        json.taken_at do
          json.scale DECAY_SCALE
        end
      end
    end
  end

  def popularity_boost(json)
    json.child! do
      json.field_value_factor do
        json.field "popularity"
        json.modifier "log2p"
      end
    end
  end

  def filtered_query_filter(json)
    json.filter do
      json.bool do
        json.set! :should do
          should_flickr(json)
          should_instagram(json)
          should_mrss(json)
        end
      end
    end if some_profile_specified?
  end

  def should_mrss(json)
    json.child! { mrss_profiles_filter(json, @mrss_names) } if @mrss_names.present?
  end

  def should_instagram(json)
    json.child! { instagram_profiles_filter(json, @instagram_profiles) } if @instagram_profiles.present?
  end

  def should_flickr(json)
    json.child! { flickr_profiles_filter(json, @flickr_groups, @flickr_users) } if @flickr_users.present? or @flickr_groups.present?
  end

  def mrss_profiles_filter(json, mrss_names)
    type_and_terms_filter(json, "mrss_photo", :mrss_names, mrss_names)
  end

  def instagram_profiles_filter(json, profiles)
    type_and_terms_filter(json, "instagram_photo", :username, profiles)
  end

  def flickr_profiles_filter(json, flickr_groups, flickr_users)
    json.bool do
      json.must do
        json.child! { json.term { json._type "flickr_photo" } }
      end
      json.set! :should do
        flickr_profiles_filter_child('owner', flickr_users, json)
        flickr_profiles_filter_child('groups', flickr_groups, json)
      end
    end
  end

  def flickr_profiles_filter_child(field, terms, json)
    json.child! { json.terms { json.set! field, terms } } if terms.present?
  end

  def filtered_query_query(json)
    json.query do
      json.bool do
        json.set! :should do
          json.child! { match_tags(json) }
          json.child! { simple_query_string(json) }
          match_phrase_collection(json)
        end
      end
    end
  end

  def match_tags(json)
    json.match do
      json.tags do
        json.query @query
        json.analyzer "tag_analyzer"
      end
    end
  end

  def simple_query_string(json)
    json.simple_query_string do
      json.fields TEXT_FIELDS
      json.query @query
      json.analyzer "en_analyzer"
      json.default_operator "AND"
    end
  end

  def pre_tags
    [DEFAULT_PRE_TAG]
  end

  def post_tags
    [DEFAULT_POST_TAG]
  end

  def some_profile_specified?
    @flickr_groups.present? or @flickr_users.present? or @instagram_profiles.present? or @mrss_names.present?
  end

  def match_phrase_collection(json)
    TEXT_FIELDS.each do |field|
      json.child! do
        json.match_phrase do
          json.set! field, @query
        end
      end
    end
  end

  def type_and_terms_filter(json, type, field, terms)
    json.bool do
      json.must do
        json.child! { json.terms { json.set! field, terms } }
        json.child! { json.term { json._type type } }
      end
    end
  end

end