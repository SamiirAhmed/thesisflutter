<?php

namespace App\Models\class_issue;

use Illuminate\Database\Eloquent\Model;

class ClassIssue extends Model
{
    protected $table = 'class_issues';
    protected $primaryKey = 'cl_issue_id';

    protected $fillable = [
        'issue_name',
        'cat_no',
    ];
}
