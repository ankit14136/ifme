# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :if_not_signed_in

  def home
    @blurbs = set_blurbs
    if user_signed_in?
      @stories = Kaminari.paginate_array(get_stories(current_user, true))
                         .page(params[:page])

      load_dashboard_data if @stories.present? && @stories.count.positive?
    else
      @posts = set_posts
    end
  end

  def blog
    @posts = set_posts
  end

  def contribute
    @blurbs = set_blurbs
    @contributors = set_contributors
  end

  def partners
    @organizations = set_organizations
  end

  def toggle_locale
    return render json: { signed_out: true } unless user_signed_in?

    change_locale!(params[:locale])
  end

  def press
    @press = set_press
  end

  def resources
    @communities = fetch_resources_for('communities')
    @education = fetch_resources_for('education')
    @hotlines = fetch_resources_for('hotlines')
    @services = fetch_resources_for('services')
  end

  def about; end

  def faq; end

  def privacy; end

  private

  def change_locale!(locale)
    response_key =
      if locale == current_user.locale
        :signed_in_no_reload
      else
        :signed_in_reload
      end

    current_user.update!(locale: locale)
    render json: { response_key => locale }
  end

  def load_dashboard_data
    params = { user_id: current_user.id }

    @moment = Moment.new
    @categories = Category.where(params).order(created_at: :desc)
    @moods = Mood.where(params).order(created_at: :desc)
  end

  def set_organizations
    organizations = JSON.parse(File.read('doc/pages/partners.json'))
    organizations.sort_by! { |o| o['name'].downcase }
  end

  def set_contributors
    contributors = JSON.parse(File.read('doc/pages/contributors.json'))
    contributors.sort_by! { |c| c['name'].downcase }
  end

  def set_blurbs
    JSON.parse(File.read('doc/pages/blurbs.json'))
  end

  def parse_author(post)
    post[1]['content']['subtitle'] || ''
  end

  def fetch_posts
    medium = Medium.new
    posts = []
    medium.posts.each do |post|
      posts.push(
        'link_name' => post[1]['title'],
        'link' => "https://medium.com/ifme/#{post[1]['uniqueSlug']}",
        'author' => parse_author(post)
      )
    end
    posts
  end

  def set_posts
    non_medium_posts = JSON.parse(File.read('doc/pages/posts.json'))
    fetch_posts.concat(non_medium_posts.reverse)
  end

  def set_press
    JSON.parse(File.read('doc/pages/press.json')).reverse
  end

  def fetch_resources_for(resource_type)
    resources = JSON.parse(File.read("doc/pages/#{resource_type}.json"))
    resources.sort_by! { |r| r['name'].downcase }
  end
end
