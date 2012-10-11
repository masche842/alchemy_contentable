require 'spec_helper'

module Alchemy
  describe Element do

    describe '#new_from_scratch' do

      it "should initialize an element by name from scratch" do
        el = Alchemy::Element.new_from_scratch({'name' => 'article'})
        el.should be_valid
      end

      it "should raise an error if the given name is not defined in the elements.yml" do
        expect { Alchemy::Element.new_from_scratch({'name' => 'foobar'}) }.to raise_error
      end

      it "should take the first part of an given name containing a hash (#)" do
        el = Alchemy::Element.new_from_scratch({'name' => 'article#header'})
        el.name.should == "article"
      end

      it "should merge given attributes into defined ones" do
        el = Alchemy::Element.new_from_scratch({'name' => 'article', 'page_id' => 1})
        el.page_id.should == 1
      end

      it "should not have forbidden attributes from definition" do
        el = Alchemy::Element.new_from_scratch({'name' => 'article'})
        el.contents.should == []
      end

    end

    context "scoped" do

      it "should return all public elements" do
        element_1 = FactoryGirl.create(:element, :public => true)
        element_2 = FactoryGirl.create(:element, :public => true)
        elements = Alchemy::Element.published.all
        elements.should include(element_1)
        elements.should include(element_2)
      end

      it "should return all elements by name" do
        element_1 = FactoryGirl.create(:element, :name => 'article')
        element_2 = FactoryGirl.create(:element, :name => 'article')
        elements = Alchemy::Element.named(['article']).all
        elements.should include(element_1)
        elements.should include(element_2)
      end

      it "should return all elements but excluded ones" do
        FactoryGirl.create(:element, :name => 'article')
        FactoryGirl.create(:element, :name => 'article')
        excluded = FactoryGirl.create(:element, :name => 'claim')
        Alchemy::Element.excluded(['claim']).all.should_not include(excluded)
      end

      context "not_in_cell" do

        it "should return all elements that are not in a cell" do
          Alchemy::Element.delete_all
          FactoryGirl.create(:element, :cell_id => 6)
          FactoryGirl.create(:element, :cell_id => nil)
          Element.not_in_cell.should have(1).element
        end

      end

    end

    describe '.all_definitions_for' do

      it "should return a list of element definitions for a list of element names" do
        element_names = ["article"]
        definitions = Alchemy::Element.all_definitions_for(element_names)
        definitions.first.fetch("name").should == 'article'
      end

      context "given 'all' as element name" do

        before do
          @element_definition = [
            {'name' => 'article'},
            {'name' => 'headline'}
          ]
          Alchemy::Element.stub!(:definitions).and_return @element_definition
        end

        it "should return all element definitions" do
          Alchemy::Element.stub!(:descriptions).and_return @element_definition
          Alchemy::Element.all_definitions_for('all').should == @element_definition
        end

      end

      it "should always return an array" do
        definitions = Alchemy::Element.all_definitions_for(nil)
        definitions.should == []
      end

    end

    context "retrieving contents, essences and ingredients" do

      let(:element) { FactoryGirl.create(:element, :name => 'news', :create_contents_after_create => true) }

      it "should return an ingredient by name" do
        element.ingredient('news_headline').should == Alchemy::EssenceText.first.ingredient
      end

      it "should return the content for rss title" do
        element.content_for_rss_title.should == element.contents.find_by_name('news_headline')
      end

      it "should return the content for rss description" do
        element.content_for_rss_description.should == element.contents.find_by_name('body')
      end

    end

    context "limited amount" do

      before do
        defs = [
          {
            'name' => 'column_headline',
            'amount' => 3,
            'contents' => [{'name' => 'headline', 'type' => 'EssenceText'}]
          },
          {
            'name' => 'unique_headline',
            'unique' => true,
            'amount' => 3,
            'contents' => [{'name' => 'headline', 'type' => 'EssenceText'}]
          }
        ]
        # F&%#ing alias methods
        Alchemy::Element.stub!(:definitions).and_return(defs)
        Alchemy::Element.stub!(:descriptions).and_return(defs)
        Alchemy::PageLayout.stub!(:get).and_return({
          'name' => 'columns',
          'elements' => ['column_headline', 'unique_headline'],
          'autogenerate' => ['unique_headline', 'column_headline', 'column_headline', 'column_headline']
        })
        @page = FactoryGirl.create(:page, :page_layout => 'columns', :do_not_autogenerate => false)
      end

      it "should be readable" do
        element = Alchemy::Element.all_definitions_for(['column_headline']).first
        element['amount'].should be 3
      end

      it "should limit elements" do
        Alchemy::Element.all_for_page(@page).each { |e| e['name'].should_not == 'column_headline' }
      end

      it "should be ignored if unique" do
        Alchemy::Element.all_for_page(@page).each { |e| e['name'].should_not == 'unique_headline' }
      end

    end

    context "collections" do

      context "for trashed elements" do

        let(:element) do
          FactoryGirl.create(:element, :page_id => 1)
        end

        it "should return a collection of trashed elements" do
          not_trashed_element = FactoryGirl.create(:element)
          element.trash
          Alchemy::Element.trashed.should include(element)
        end

        it "should return a collection of not trashed elements" do
          Alchemy::Element.not_trashed.should include(element)
        end

      end

    end

    describe "#trash" do

      before(:each) do
        @element = FactoryGirl.create(:element, :page_id => 1, :cell_id => 1)
        @element.trash
      end

      it "should remove the elements position" do
        @element.position.should == nil
      end

      it "should set the public state to false" do
        @element.public?.should == false
      end

      it "should not remove the page_id" do
        pending "alchemy 2.3!"
        @element.page_id.should == 1
      end

      it "should not remove the cell_id" do
        pending "alchemy 2.3!"
        @element.cell_id.should == 1
      end

      it "it should be possible to trash more than one element from the same page" do
        trashed_element_2 = FactoryGirl.create(:element, :page_id => 1)
        trashed_element_2.trash
        Alchemy::Element.trashed.should include(@element, trashed_element_2)
      end

    end

    it "should raise error if all_for_page method has no page" do
      expect { Alchemy::Element.all_for_page(nil) }.to raise_error(TypeError)
    end

    describe "#content_by_type" do

      before(:each) do
        @element = FactoryGirl.create(:element, :name => 'headline')
        @content = @element.contents.first
      end

      context "with namespaced essence type" do

        it "should return content by passing a essence type" do
          @element.content_by_type('Alchemy::EssenceText').should == @content
        end

      end

      context "without namespaced essence type" do

        it "should return content by passing a essence type" do
          @element.content_by_type('EssenceText').should == @content
        end

      end

    end

    describe "#all_contents_by_type" do

      before(:each) do
        @element = FactoryGirl.create(:element)
        @contents = @element.contents.select { |c| c.essence_type == 'Alchemy::EssenceText' }
      end

      context "with namespaced essence type" do

        it "should return content by passing a essence type" do
          @element.all_contents_by_type('Alchemy::EssenceText').should == @contents
        end

      end

      context "without namespaced essence type" do

        it "should return content by passing a essence type" do
          @element.all_contents_by_type('EssenceText').should == @contents
        end

      end

    end

    describe '#copy' do

      let(:element) { FactoryGirl.create(:element, :create_contents_after_create => true) }

      it "should not create contents from scratch" do
        copy = Alchemy::Element.copy(element)
        copy.contents.count.should == element.contents.count
      end

      it "should create a new record with all attributes of source except given differences" do
        copy = Alchemy::Element.copy(element, {:name => 'foobar'})
        copy.name.should == 'foobar'
      end

      it "should make copies of all contents of source" do
        copy = Alchemy::Element.copy(element)
        copy.contents.collect(&:id).should_not == element.contents.collect(&:id)
      end

    end

    describe "Finding previous or next element." do

      let(:page) { FactoryGirl.create(:language_root_page) }

      before(:each) do
        @element1 = FactoryGirl.create(:element, :page => page, :name => 'headline')
        @element2 = FactoryGirl.create(:element, :page => page)
        @element3 = FactoryGirl.create(:element, :page => page, :name => 'text')
      end

      describe '#prev' do

        it "should return previous element on same page" do
          @element2.prev.should == @element1
        end

        context "with name as parameter" do
          it "should return previous of this kind" do
            @element3.prev('headline').should == @element1
          end
        end

      end

      describe '#next' do

        it "should return next element on same page" do
          @element1.next.should == @element2
        end

        context "with name as parameter" do
          it "should return next of this kind" do
            @element1.next('text').should == @element3
          end
        end

      end

    end

    describe '#belonging_cellnames' do

      before do
        @page = FactoryGirl.create(:public_page)
        @element = FactoryGirl.create(:element, :page => @page)
      end

      context "with page having cells defining the correct elements" do

        before do
          Alchemy::Cell.stub!(:definitions).and_return([
            {'name' => 'header', 'elements' => ['article', 'headline']},
            {'name' => 'footer', 'elements' => ['article', 'text']},
            {'name' => 'sidebar', 'elements' => ['teaser']}
          ])
        end

        it "should return a list of all cells from given page this element could be placed in" do
          @header_cell = FactoryGirl.create(:cell, :name => 'header', :page => @page)
          @footer_cell = FactoryGirl.create(:cell, :name => 'footer', :page => @page)
          @sidebar_cell = FactoryGirl.create(:cell, :name => 'sidebar', :page => @page)
          @element.belonging_cellnames(@page).should include('header')
          @element.belonging_cellnames(@page).should include('footer')
        end

        context "but without any cells" do

          it "should return the 'nil cell'" do
            @element.belonging_cellnames(@page).should == ['for_other_elements']
          end

        end

      end

      context "with page having cells defining the wrong elements" do

        before do
          Alchemy::Cell.stub!(:definitions).and_return([
            {'name' => 'header', 'elements' => ['download', 'headline']},
            {'name' => 'footer', 'elements' => ['contactform', 'text']},
            {'name' => 'sidebar', 'elements' => ['teaser']}
          ])
        end

        it "should return the 'nil cell'" do
          @header_cell = FactoryGirl.create(:cell, :name => 'header', :page => @page)
          @footer_cell = FactoryGirl.create(:cell, :name => 'footer', :page => @page)
          @sidebar_cell = FactoryGirl.create(:cell, :name => 'sidebar', :page => @page)
          @element.belonging_cellnames(@page).should == ['for_other_elements']
        end

      end

    end

  end
end