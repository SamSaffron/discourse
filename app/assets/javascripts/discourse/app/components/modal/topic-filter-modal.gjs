import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import DMultiSelect from "discourse/components/d-multi-select";
import Form from "discourse/components/form";
import Category from "discourse/models/category";
import { i18n } from "discourse-i18n";
import TagChooser from "select-kit/components/tag-chooser";

export default class TopicFilterModal extends Component {
  @service modal;

  @tracked categories = [];
  @tracked tags = [];
  @tracked status = "";
  @tracked startDate;
  @tracked endDate;

  statusOptions = [
    { id: "", name: i18n("filter_modal.status.any") },
    { id: "open", name: i18n("filter_modal.status.open") },
    { id: "closed", name: i18n("filter_modal.status.closed") },
    { id: "archived", name: i18n("filter_modal.status.archived") },
    { id: "listed", name: i18n("filter_modal.status.listed") },
    { id: "unlisted", name: i18n("filter_modal.status.unlisted") },
  ];

  loadCategories = async (filter) => {
    let categories = Category.list();
    if (filter) {
      filter = filter.toLowerCase();
      categories = categories.filter((c) => {
        return (
          Category.slugFor(c).toLowerCase().includes(filter) ||
          c.name.toLowerCase().includes(filter)
        );
      });
    }
    return categories.map((c) => ({ id: Category.slugFor(c), name: c.name }));
  };

  @action
  apply(){
    let query = [];
    if (this.categories.length) {
      query.push(`category:${this.categories.map((c) => c.id).join(",")}`);
    }
    if (this.tags.length) {
      query.push(`tag:${this.tags.join(",")}`);
    }
    if (this.status) {
      query.push(`status:${this.status}`);
    }
    if (this.startDate) {
      query.push(`created-after:${this.startDate}`);
    }
    if (this.endDate) {
      query.push(`created-before:${this.endDate}`);
    }

    this.args.model.updateQueryString(query.join(" "));
    this.args.closeModal();
  }

  <template>
    <DModal
      @title={{i18n "filter_modal.title"}}
      @closeModal={{@closeModal}}
      class="topic-filter-modal"
    >
      <:body>
        <Form @onSubmit={{this.apply}} as |form|>
          <form.Row>
            <form.Field @title={{i18n "filter_modal.categories"}}>
              <DMultiSelect
                @selection={{this.categories}}
                @loadFn={{this.loadCategories}}
                @onChange={{fn (mut this.categories)}}
              >
                <:selection as |item|>{{item.name}}</:selection>
                <:result as |item|>{{item.name}}</:result>
              </DMultiSelect>
            </form.Field>
          </form.Row>
          <form.Row>
            <form.Field @title={{i18n "filter_modal.tags"}}>
              <TagChooser @tags={{this.tags}} @onChange={{fn (mut this.tags)}} @unlimitedTagCount={{true}} />
            </form.Field>
          </form.Row>
          <form.Row>
            <form.Field @title={{i18n "filter_modal.status.label"}} as |field|>
              <field.Select @value={{this.status}} @onChange={{fn (mut this.status)}} as |select|>
                {{#each this.statusOptions as |opt|}}
                  <select.Option @value={{opt.id}}>{{opt.name}}</select.Option>
                {{/each}}
              </field.Select>
            </form.Field>
          </form.Row>
          <form.Row>
            <form.Field @title={{i18n "filter_modal.date"}} as |field|>
              <div class="date-range-inputs">
                <field.Input @type="date" @value={{this.startDate}} @onChange={{fn (mut this.startDate)}} />
                <span class="separator">-</span>
                <field.Input @type="date" @value={{this.endDate}} @onChange={{fn (mut this.endDate)}} />
              </div>
            </form.Field>
          </form.Row>
        </Form>
      </:body>
      <:footer>
        <DButton class="btn-primary" @label="filter_modal.apply" @action={{this.apply}} />
        <DButton class="btn-flat d-modal-cancel" @label="filter_modal.cancel" @action={{@closeModal}} />
      </:footer>
    </DModal>
  </template>
}

