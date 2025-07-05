import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { array, fn, hash } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import DateInput from "discourse/components/date-input";
import Form from "discourse/components/form";
import Category from "discourse/models/category";
import { i18n } from "discourse-i18n";
import CategoryChooser from "select-kit/components/category-chooser";
import DropdownSelectBox from "select-kit/components/dropdown-select-box";
import TagChooser from "select-kit/components/tag-chooser";

export default class TopicFilterModal extends Component {
  @service modal;

  @tracked categoryId;
  @tracked tags = [];
  @tracked status;
  @tracked createdAfter;
  @tracked createdBefore;

  constructor() {
    super(...arguments);
    const q = this.args.currentQueryString;
    if (q) {
      let m = q.match(/category:([^\s]+)/);
      if (m) {
        const c = Category.findSingleBySlug(m[1]);
        this.categoryId = c?.id;
      }
      m = q.match(/tag:([^\s]+)/);
      if (m) {
        this.tags = m[1].split(",");
      }
      m = q.match(/status:([^\s]+)/);
      if (m) {
        this.status = m[1];
      }
      m = q.match(/created-after:([^\s]+)/);
      if (m) {
        this.createdAfter = m[1];
      }
      m = q.match(/created-before:([^\s]+)/);
      if (m) {
        this.createdBefore = m[1];
      }
    }
  }

  buildQueryString() {
    const parts = [];
    if (this.categoryId) {
      const cat = Category.findById(this.categoryId);
      parts.push(`category:${Category.slugFor(cat)}`);
    }
    if (this.tags.length) {
      parts.push(`tag:${this.tags.join(",")}`);
    }
    if (this.status) {
      parts.push(`status:${this.status}`);
    }
    if (this.createdAfter) {
      parts.push(`created-after:${this.createdAfter}`);
    }
    if (this.createdBefore) {
      parts.push(`created-before:${this.createdBefore}`);
    }
    return parts.join(" ");
  }

  @action
  apply() {
    this.args.onApply?.(this.buildQueryString());
    this.modal.close();
  }

  <template>
    <DModal @title={{i18n "filters_modal.title"}} class="topic-filter-modal">
      <:body>
        <Form as |form|>
          <form.Field @name="category" @title={{i18n "filters_modal.category"}}>
            <CategoryChooser
              @value={{this.categoryId}}
              @onChange={{fn (mut this.categoryId)}}
            />
          </form.Field>
          <form.Field @name="tags" @title={{i18n "filters_modal.tags"}}>
            <TagChooser @tags={{this.tags}} @onChange={{fn (mut this.tags)}} />
          </form.Field>
          <form.Field @name="status" @title={{i18n "filters_modal.status"}}>
            <DropdownSelectBox
              @value={{this.status}}
              @content={{array
                (hash id="" name="")
                (hash id="open" name=(i18n "filters_modal.statuses.open"))
                (hash id="closed" name=(i18n "filters_modal.statuses.closed"))
                (hash
                  id="archived" name=(i18n "filters_modal.statuses.archived")
                )
                (hash id="listed" name=(i18n "filters_modal.statuses.listed"))
                (hash
                  id="unlisted" name=(i18n "filters_modal.statuses.unlisted")
                )
                (hash id="deleted" name=(i18n "filters_modal.statuses.deleted"))
                (hash id="public" name=(i18n "filters_modal.statuses.public"))
              }}
              @onChange={{fn (mut this.status)}}
            />
          </form.Field>
          <form.Field
            @name="created_after"
            @title={{i18n "filters_modal.created_after"}}
          >
            <DateInput
              @date={{this.createdAfter}}
              @onChange={{fn (mut this.createdAfter)}}
            />
          </form.Field>
          <form.Field
            @name="created_before"
            @title={{i18n "filters_modal.created_before"}}
          >
            <DateInput
              @date={{this.createdBefore}}
              @onChange={{fn (mut this.createdBefore)}}
            />
          </form.Field>
        </Form>
      </:body>
      <:footer>
        <DButton
          @action={{this.apply}}
          @label={{i18n "filters_modal.apply"}}
          class="btn-primary"
        />
      </:footer>
    </DModal>
  </template>
}
