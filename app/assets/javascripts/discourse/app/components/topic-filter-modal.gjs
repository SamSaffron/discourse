import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { array, hash } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import Form from "discourse/form-kit/components/fk/form";
import { i18n } from "discourse-i18n";
import ComboBox from "select-kit/components/combo-box";
import SearchAdvancedCategoryChooser from "select-kit/components/search-advanced-category-chooser";
import TagChooser from "select-kit/components/tag-chooser";

/**
 * Modal for building advanced topic filter queries.
 *
 * @component TopicFilterModal
 * @arg model.currentQuery {string} The current filter query string
 * @arg model.apply {function} Callback to apply the built query
 */
export default class TopicFilterModal extends Component {
  @service modal;

  /**
   * API handle provided by FormKit form.
   *
   * @type {object}
   */
  @tracked formApi;

  get statusOptions() {
    return [
      { name: i18n("filters.advanced_filter.status.open"), value: "open" },
      { name: i18n("filters.advanced_filter.status.closed"), value: "closed" },
    ];
  }

  /**
   * Stores the form API for later manipulation.
   *
   * @param {object} api
   */
  @action
  registerApi(api) {
    this.formApi = api;
  }

  /**
   * Updates the form's tag field.
   *
   * @param {Array<string>} tags
   */
  @action
  updateTags(tags) {
    this.formApi.set("tags", tags);
  }

  /**
   * Applies the form data to build a query string and
   * triggers the provided apply callback.
   *
   * @param {object} data
   */
  @action
  apply(data) {
    let query = data.query?.trim() || "";
    if (data.category) {
      query = `${query} category:${data.category}`.trim();
    }
    if (data.tags?.length) {
      query = `${query} tags:${data.tags.join(",")}`.trim();
    }
    if (data.status) {
      query = `${query} status:${data.status}`.trim();
    }
    if (data.min_posts) {
      query = `${query} min_posts:${data.min_posts}`.trim();
    }
    if (data.max_posts) {
      query = `${query} max_posts:${data.max_posts}`.trim();
    }
    if (data.min_views) {
      query = `${query} min_views:${data.min_views}`.trim();
    }
    if (data.max_views) {
      query = `${query} max_views:${data.max_views}`.trim();
    }
    this.args.model.apply?.(query);
    this.modal.close();
  }

  <template>
    <Form
      @data={{hash
        query=this.args.model.currentQuery
        category=null
        tags=(array)
        status=null
        min_posts=null
        max_posts=null
        min_views=null
        max_views=null
      }}
      @onRegisterApi={{this.registerApi}}
      @onSubmit={{this.apply}}
      class="topic-filter-modal"
      as |f|
    >
      <f.Field @name="query" @title="filters.filter.button.label" as |field|>
        <field.Input @type="text" />
      </f.Field>
      <f.Field
        @name="category"
        @title="filters.advanced_filter.categories"
        as |field|
      >
        <SearchAdvancedCategoryChooser
          @value={{field.value}}
          @onChange={{field.set}}
        />
      </f.Field>
      <f.Field @name="tags" @title="filters.advanced_filter.tags" as |field|>
        <TagChooser
          @tags={{field.value}}
          @onChange={{this.updateTags}}
          @everyTag={{true}}
          @unlimitedTagCount={{true}}
        />
      </f.Field>
      <f.Field
        @name="status"
        @title="filters.advanced_filter.status.label"
        as |field|
      >
        <ComboBox
          @value={{field.value}}
          @content={{this.statusOptions}}
          @onChange={{field.set}}
        />
      </f.Field>
      <f.Field
        @name="min_posts"
        @title="filters.advanced_filter.posts.min"
        as |field|
      >
        <field.Input @type="number" />
      </f.Field>
      <f.Field
        @name="max_posts"
        @title="filters.advanced_filter.posts.max"
        as |field|
      >
        <field.Input @type="number" />
      </f.Field>
      <f.Field
        @name="min_views"
        @title="filters.advanced_filter.views.min"
        as |field|
      >
        <field.Input @type="number" />
      </f.Field>
      <f.Field
        @name="max_views"
        @title="filters.advanced_filter.views.max"
        as |field|
      >
        <field.Input @type="number" />
      </f.Field>
      <f.Actions>
        <DButton
          @label="filters.advanced_filter.apply"
          @action={{f.submit}}
          class="btn-primary"
        />
      </f.Actions>
    </Form>
  </template>
}
