<?php

namespace App\Models\class_issue;

use Illuminate\Database\Eloquent\Model;
use App\Models\ClassLeader;

class ClassIssueComplaint extends Model
{
    protected $table = 'class_issues_complaints';
    protected $primaryKey = 'cl_is_co_no';

    protected $fillable = [
        'cl_issue_id',
        'description',
        'lead_id',
        'status', // Added status for convenience, though tracking table also has it
    ];

    public function issue()
    {
        return $this->belongsTo(ClassIssue::class, 'cl_issue_id', 'cl_issue_id');
    }

    public function leader()
    {
        return $this->belongsTo(ClassLeader::class, 'lead_id', 'lead_id');
    }

    public function tracking()
    {
        return $this->hasMany(ClassIssueTracking::class, 'cl_is_co_no', 'cl_is_co_no');
    }
}
