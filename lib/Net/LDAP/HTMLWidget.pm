package Net::LDAP::HTMLWidget;
use strict;
use warnings;

our $VERSION = '0.01';
# pod after __END__

sub fill_widget {
    my ($self,$entry,$widget)=@_;

    foreach my $element ( @{ $widget->{_elements} } ) {
        my $name=$element->name;
        next unless $name && $entry->exists($name) && $element->can('value');
	$element->value( $entry->get_value($name) );
    }
}


sub populate_from_widget {
    my ($self,$entry,$result,$ldap)=@_;

    $ldap=$self if ref $self && ($self->isa('Net::LDAP') || $self->isa('Catalyst::Model::LDAP'));

    foreach my $oc ( ref $entry->get_value('objectClass') ? @{$entry->get_value('objectClass')} : ($entry->get_value('objectClass'))) {
	foreach my $attr ($ldap->schema->must($oc),$ldap->schema->may($oc)) {
	    $entry->replace($attr->{name}, $result->param($attr->{name})) 
		if defined $result->param($attr->{name});
	}
    }
    return $entry->update($ldap);
}


1;

__END__

=pod

=head1 NAME

Net::LDAP::HTMLWidget - Like FromForm but with Net::LDAP and HTML::Widget

=head1 SYNOPSIS

You'll need a working Net::LDAP setup and some knowledge of HTML::Widget
and Catalyst. If you have no idea what I'm talking about, check the (sparse)
docs of those modules.

   
   package My::Controller::Pet;    # Catalyst-style
   
   # define the widget in a sub (DRY)
   sub widget_pet {
     my ($self,$c)=@_;
     my $w=$c->widget('pet')->method('get');
     $w->element('Textfield','name')->label('Name');
     $w->element('Textfield','age')->label('Age');
     ...
     return $w;
   }
     
   # this renders an edit form with values filled in from the DB 
   sub edit : Local {
     my ($self,$c,$id)=@_;
  
     # get the object
     my $item=$c->model('LDAP')->search(uid=>$id);
     $c->stash->{item}=$item;
  
     # get the widget
     my $w=$self->widget_pet($c);
     $w->action($c->uri_for('do_edit/'.$id));
    
     # fill widget with data from DB
     Net::LDAP::HTMLWidget->fill_widget($item,$w);
  }
  
  sub do_edit : Local {
    my ($self,$c,$id)=@_;
    
    # get the object from DB
    my $item=$c->model('LDAP')->search(uid=>$id);
    $c->stash->{item}=$item;
    
    $ get the widget
    my $w=$self->widget_pet($c);
    $w->action($c->uri_for('do_edit/'.$id));
    
    # process the form parameters
    my $result = $w->process($c->req);
    $c->stash->{'result'}=$result;
    
    # if there are no errors save the form values to the object
    unless ($result->has_errors) {
        Net::LDAP::HTMLWidget->populate_from_widget($item,$result);
        $c->res->redirect('/users/pet/'.$id);
    }
  }

  
=head1 DESCRIPTION

Something like Class::DBI::FromForm / Class::DBI::FromCGI but using
HTML::Widget for form creation and validation and DBIx::Class as a ORM.

=head2 Methods

=head3 fill_widget

   $dbic_object->fill_widget($widget);

Fill the values of a widgets elements with the values of the DBIC object.

=head3 populate_from_widget

   my $obj=$schema->resultset('pet)->new->populate_from_widget($result);
   my $item->populate_from_widget($result);

Create or update a DBIx::Class row from a HTML::Widget::Result object
   
=head1 AUTHOR

Thomas Klausner, <domm@cpan.org>, http://domm.zsi.at
Marcus Ramberg, <mramberg@cpan.org>

=head1 LICENSE

This code is Copyright (c) 2003-2006 Thomas Klausner.
All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.

=cut




