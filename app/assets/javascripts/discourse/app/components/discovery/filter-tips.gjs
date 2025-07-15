import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { cancel, debounce } from "@ember/runloop";
import { service } from "@ember/service";
import { and, eq } from "truth-helpers";
import DButton from "discourse/components/d-button";
import concatClass from "discourse/helpers/concat-class";
import { ajax } from "discourse/lib/ajax";

export default class FilterTips extends Component {
  @service currentUser;
  @service site;

  @tracked showTips = false;
  @tracked currentInputValue = "";
  @tracked isSearchingValues = false;
  @tracked searchResults = [];
  @tracked activeFilter = null;
  searchTimer = null;
  @tracked _selectedIndex = -1;

  willDestroy() {
    super.willDestroy(...arguments);
    if (this.searchTimer) {
      cancel(this.searchTimer);
      this.searchTimer = null;
    }
    if (this.inputElement) {
      this.inputElement.removeEventListener("focus", this.handleInputFocus);
      this.inputElement.removeEventListener("blur", this.handleInputBlur);
      this.inputElement.removeEventListener("keydown", this.handleKeyDown);
      this.inputElement.removeEventListener("input", this.handleInput);
    }
  }

  get selectedIndex() {
    return this._selectedIndex;
  }

  set selectedIndex(value) {
    this._selectedIndex = value;
    this.args.blockEnterSubmit(value !== -1);
  }

  get currentItems() {
    let results = this.isSearchingValues
      ? this.searchResults
      : this.filteredTips;
    return results;
  }

  get filteredTips() {
    if (!this.args.tips) {
      return [];
    }

    const words = this.currentInputValue.split(/\s+/);
    const lastWord = words[words.length - 1].toLowerCase();

    if (!this.currentInputValue || lastWord === "") {
      return this.args.tips
        .filter((tip) => tip.priority)
        .sort((a, b) => (b.priority || 0) - (a.priority || 0))
        .slice(0, 10);
    }

    return this.args.tips
      .filter((tip) => {
        const filterName = tip.name.split(":")[0];
        return filterName.toLowerCase().startsWith(lastWord);
      })
      .sort((a, b) => a.name.localeCompare(b.name))
      .slice(0, 10);
  }

  @action
  performValueSearch(filterName, valueText) {
    if (this.searchTimer) {
      cancel(this.searchTimer);
    }

    this.searchTimer = debounce(
      this,
      this._performValueSearch,
      filterName,
      valueText,
      300
    );
  }

  async _performValueSearch(filterName, valueText) {
    let searchType;
    if (filterName === "tag" || filterName === "-tag") {
      searchType = "tag";
    } else if (filterName === "category" || filterName === "-category") {
      searchType = "category";
    } else if (filterName === "created-by") {
      searchType = "user";
    } else {
      return;
    }

    if (searchType === "tag") {
      try {
        const response = await ajax("/tags/filter/search.json", {
          data: { q: valueText || "", limit: 5 },
        });
        this.searchResults = response.results.map((tag) => ({
          value: `${filterName}:${tag.name}`,
          label: `${filterName}:${tag.name} (${tag.count})`,
        }));
      } catch {
        this.searchResults = [];
      }
    } else if (searchType === "category") {
      const categories = this.site.categories || [];
      const filtered = categories
        .filter((c) => {
          const name = c.name.toLowerCase();
          const slug = c.slug.toLowerCase();
          const search = (valueText || "").toLowerCase();
          return name.includes(search) || slug.includes(search);
        })
        .slice(0, 10)
        .map((c) => ({
          value: `${filterName}:${c.slug}`,
          label: `${filterName}:${c.name}`,
        }));
      this.searchResults = filtered;
    } else if (searchType === "user") {
      try {
        const response = await ajax("/u/search/users", {
          data: { term: valueText || "", limit: 10 },
        });
        this.searchResults = response.users.map((user) => ({
          value: `${filterName}:@${user.username}`,
          label: `${filterName}:@${user.username}`,
        }));
      } catch {
        this.searchResults = [];
      }
    }
  }

  @action
  setupEventListeners(element) {
    this.element = element;
    this.inputElement = document.querySelector("#queryStringInput");
    if (this.inputElement) {
      this.inputElement.addEventListener("focus", this.handleInputFocus);
      this.inputElement.addEventListener("blur", this.handleInputBlur);
      this.inputElement.addEventListener("keydown", this.handleKeyDown);
      this.inputElement.addEventListener("input", this.handleInput);
    }
  }

  @action
  handleInput(event) {
    this.currentInputValue = event.target.value;
    this.selectedIndex = -1;

    // Check if we're entering a value for a searchable filter
    const words = this.currentInputValue.split(/\s+/);
    const lastWord = words[words.length - 1];
    const colonIndex = lastWord.indexOf(":");

    if (colonIndex > 0) {
      const filterName = lastWord.substring(0, colonIndex);
      const valueText = lastWord.substring(colonIndex + 1);

      // Check if this is a searchable filter
      if (
        ["tag", "-tag", "category", "-category", "created-by"].includes(
          filterName
        )
      ) {
        this.isSearchingValues = true;
        this.activeFilter = filterName;
        this.performValueSearch(filterName, valueText);
      } else {
        this.isSearchingValues = false;
        this.activeFilter = null;
      }
    } else {
      this.isSearchingValues = false;
      this.activeFilter = null;
    }
  }

  @action
  handleInputFocus(event) {
    this.currentInputValue = event.target.value;
    this.showTips = true;
    this.selectedIndex = -1;
  }

  @action
  handleInputBlur() {
    if (!this.element?.contains(document.activeElement)) {
      this.showTips = false;
      this.isSearchingValues = false;
      this.activeFilter = null;
    }
  }

  @action
  handleKeyDown(event) {
    if (!this.showTips || this.currentItems.length === 0) {
      return;
    }

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault();
        if (this.selectedIndex === -1) {
          this.selectedIndex = 0;
        } else {
          this.selectedIndex =
            (this.selectedIndex + 1) % this.currentItems.length;
        }
        break;
      case "ArrowUp":
        event.preventDefault();
        if (this.selectedIndex === -1) {
          this.selectedIndex = this.currentItems.length - 1;
        } else {
          this.selectedIndex =
            (this.selectedIndex - 1 + this.currentItems.length) %
            this.currentItems.length;
        }
        break;
      case "Tab":
        event.preventDefault();
        event.stopPropagation();
        const indexToUse = this.selectedIndex === -1 ? 0 : this.selectedIndex;
        if (indexToUse < this.currentItems.length) {
          if (this.isSearchingValues) {
            this.selectValue(this.currentItems[indexToUse]);
          } else {
            this.selectTip(this.currentItems[indexToUse]);
          }
        }
        break;
      case "Enter":
        if (this.selectedIndex >= 0) {
          event.preventDefault();
          event.stopPropagation();
          event.stopImmediatePropagation();
          if (this.isSearchingValues) {
            this.selectValue(this.currentItems[this.selectedIndex]);
          } else {
            this.selectTip(this.currentItems[this.selectedIndex]);
          }
        }
        break;
      case "Escape":
        this.showTips = false;
        this.isSearchingValues = false;
        this.activeFilter = null;
        break;
    }
  }

  @action
  selectTip(tip) {
    const words = this.currentInputValue.split(/\s+/);
    const filterName = tip.name;
    words[words.length - 1] = filterName;
    if (filterName[-1] !== ":") {
      words[words.length - 1] += " ";
    }
    const updatedValue = words.join(" ");

    this.args.onSelectTip(updatedValue);
    this.selectedIndex = -1;

    if (
      ["tag", "-tag", "category", "-category", "created-by"].includes(
        filterName
      )
    ) {
      this.isSearchingValues = true;
      this.activeFilter = filterName;
      this.performValueSearch(filterName, "");
    }
    if (this.inputElement) {
      this.inputElement.focus();
      this.inputElement.setSelectionRange(
        updatedValue.length,
        updatedValue.length
      );
    }
  }

  @action
  selectValue(item) {
    const words = this.currentInputValue.split(/\s+/);
    words[words.length - 1] = item.value;
    const updatedValue = words.join(" ") + " ";

    this.args.onSelectTip(updatedValue);
    this.isSearchingValues = false;
    this.activeFilter = null;
    this.selectedIndex = -1;

    if (this.inputElement) {
      this.inputElement.focus();
      this.inputElement.setSelectionRange(
        updatedValue.length,
        updatedValue.length
      );
    }
  }

  <template>
    <div class="filter-tips" {{didInsert this.setupEventListeners}}>
      {{#if (and this.showTips this.currentItems.length)}}
        <div class="filter-tips__dropdown">
          {{#if this.isSearchingValues}}
            {{#each this.searchResults as |item index|}}
              <DButton
                @class={{concatClass
                  "filter-tip"
                  (if (eq index this.selectedIndex) "selected")
                }}
                @action={{fn this.selectValue item}}
              >
                <span class="filter-value">{{item.label}}</span>
              </DButton>
            {{/each}}
          {{else}}
            {{#each this.filteredTips as |tip index|}}
              <DButton
                @class={{concatClass
                  "filter-tip"
                  (if (eq index this.selectedIndex) "selected")
                }}
                @action={{fn this.selectTip tip}}
              >
                <span class="filter-name">{{tip.name}}</span>
                {{#if tip.description}}
                  <span class="filter-description">— {{tip.description}}</span>
                {{/if}}
              </DButton>
            {{/each}}
          {{/if}}
        </div>
      {{/if}}
    </div>
  </template>
}
