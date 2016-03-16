//
//  ZBJCalendarView.m
//  ZBJCalendar
//
//  Created by wanggang on 2/24/16.
//  Copyright © 2016 ZBJ. All rights reserved.
//

#import "ZBJCalendarView.h"
#import "ZBJCalendarWeekView.h"
#import "NSDate+ZBJAddition.h"
#import "NSDate+IndexPath.h"

typedef CF_ENUM(NSInteger, ZBJCalendarSelectedState) {
    ZBJCalendarStateSelectedNone,
    ZBJCalendarStateSelectedStart,
    ZBJCalendarStateSelectedRange,
};

@interface ZBJCalendarView () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) ZBJCalendarWeekView *weekView;

@property (nonatomic, strong) NSString *cellIdentifier;
@property (nonatomic, strong) NSString *sectionHeaderIdentifier;
@property (nonatomic, strong) NSString *sectionFooterIdentifier;

@end

@implementation ZBJCalendarView

#pragma  mark - Override
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor whiteColor];
        [self addSubview:self.weekView];
        [self addSubview:self.collectionView];
        
        self.selectionMode = ZBJSelectionModeRange;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.weekView.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), 45);
    
    self.collectionView.frame = CGRectMake(0,
                                           CGRectGetMaxY(self.weekView.frame),
                                           CGRectGetWidth(self.frame),
                                           CGRectGetHeight(self.frame) - CGRectGetMaxY(self.weekView.frame));
    
    
    NSInteger collectionContentWidth = CGRectGetWidth(self.collectionView.frame) - self.contentInsets.left - self.contentInsets.right;
    NSInteger residue = collectionContentWidth % 7;

    CGFloat cellWidth = collectionContentWidth / 7.0;
    if (residue != 0) {
        
        CGFloat newPadding;
        if (residue > 7.0 / 2) {
            newPadding = self.contentInsets.left - (7 - residue) / 2.0;
            cellWidth = (collectionContentWidth + 7 - residue) / 7.0;
        } else {
            newPadding = self.contentInsets.left + (residue / 2.0);
            cellWidth = (collectionContentWidth - residue) / 7.0;
        }
        
        UIEdgeInsets inset = UIEdgeInsetsMake(self.contentInsets.top, newPadding, self.contentInsets.bottom, newPadding);
        self.contentInsets = inset;
    }
    self.collectionView.contentInset = self.contentInsets;
    
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    layout.itemSize = CGSizeMake(cellWidth, cellWidth);
    self.collectionView.collectionViewLayout = layout;
    
}

#pragma mark - public method
- (void)registerCellClass:(id)clazz withReuseIdentifier:(NSString *)identifier {
    self.cellIdentifier = identifier;
    [self.collectionView registerClass:clazz forCellWithReuseIdentifier:identifier];
}

- (void)registerSectionHeader:(id)clazz withReuseIdentifier:(NSString *)identifier{
    self.sectionHeaderIdentifier = identifier;
    [self.collectionView registerClass:clazz forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:identifier];
}

- (void)registerSectionFooter:(id)clazz withReuseIdentifier:(NSString *)identifier{
    self.sectionFooterIdentifier = identifier;
    [self.collectionView registerClass:clazz forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:identifier];
}

- (void)setContentInsets:(UIEdgeInsets)contentInsets {
    _contentInsets = contentInsets;
    self.weekView.contentInsets = _contentInsets;
    self.collectionView.contentInset = _contentInsets;

}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    self.collectionView.backgroundColor = backgroundColor;
    self.weekView.backgroundColor = backgroundColor;
}

#pragma mark UICollectionViewDataSource

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    NSDate *firstDateOfMonth = [NSDate dateForFirstDayInSection:indexPath.section firstDate:self.firstDate];
    
    NSCalendar *calendar = [NSDate gregorianCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:firstDateOfMonth];
    
    if (self.sectionHeaderIdentifier && [kind isEqualToString:UICollectionElementKindSectionHeader]) {
        id headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:self.sectionHeaderIdentifier forIndexPath:indexPath];
        if (self.delegate && [self.delegate respondsToSelector:@selector(calendarView:configureSectionHeaderView:forYear:month:)]) {
            [self.delegate calendarView:self configureSectionHeaderView:headerView forYear:components.year month:components.month];
        }
        return headerView;
    } else if (self.sectionFooterIdentifier && [kind isEqualToString:UICollectionElementKindSectionFooter]) {
        id footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:self.sectionFooterIdentifier forIndexPath:indexPath];

        if (self.delegate && [self.delegate respondsToSelector:@selector(calendarView:configureSectionFooterView:forYear:month:)]) {
            [self.delegate calendarView:self configureSectionFooterView:footerView forYear:components.year month:components.month];
        }
        return footerView;
    }
   
    return NULL;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSDate *firstDay = [NSDate dateForFirstDayInSection:section firstDate:self.firstDate];
    NSInteger weekDay = [firstDay weekday] -1;
    NSInteger items =  weekDay + [NSDate numberOfDaysInMonth:firstDay];
    return items;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    NSInteger months = [NSDate numberOfMonthsFromDate:self.firstDate toDate:self.lastDate];
    return months;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    id cell = [collectionView dequeueReusableCellWithReuseIdentifier:self.cellIdentifier forIndexPath:indexPath];
    
    NSDate *date = [NSDate dateAtIndexPath:indexPath firstDate:self.firstDate];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(calendarView:configureCell:forDate:)]) {
        [self.delegate calendarView:self configureCell:cell forDate:date];
    }
   
    return cell;
}


#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDate *date = [NSDate dateAtIndexPath:indexPath firstDate:self.firstDate];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(calendarView:shouldSelectDate:)]) {
        return [self.delegate calendarView:self shouldSelectDate:date];
    }
    
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
   
    NSDate *date = [NSDate dateAtIndexPath:indexPath firstDate:self.firstDate];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(calendarView:didSelectDate:)]) {
        [self.delegate calendarView:self didSelectDate:date];
    }
}


#pragma mark UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (self.sectionHeaderIdentifier) {
        if (self.sectionHeaderHeight > 0) {
            return CGSizeMake(CGRectGetWidth(collectionView.frame), self.sectionHeaderHeight);
        } else {
            return CGSizeMake(CGRectGetWidth(collectionView.frame), 52);
        }
    }
    return CGSizeZero;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    if (self.sectionFooterIdentifier) {
        if (self.sectionFooterIdentifier > 0) {
            return CGSizeMake(CGRectGetWidth(collectionView.frame), self.sectionFooterHeight);
        } else {
            return CGSizeMake(CGRectGetWidth(collectionView.frame), 13);
        }
    }
    return CGSizeZero;
}

#pragma mark - getters

- (ZBJCalendarWeekView *)weekView {
    if (!_weekView) {
        _weekView = [[ZBJCalendarWeekView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), 45)];
    }
    return _weekView;
}



- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.weekView.frame), CGRectGetWidth(self.frame), CGRectGetHeight(self.frame) - CGRectGetMaxY(self.weekView.frame)) collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
    }
    return _collectionView;
}


#pragma mark - setters
- (void)setSelectionMode:(ZBJSelectionMode)selectionMode {
    _selectionMode = selectionMode;
    switch (_selectionMode) {
        case ZBJSelectionModeSingle: {
            self.collectionView.allowsSelection = YES;
            break;
        }
        case ZBJSelectionModeRange: {
            self.collectionView.allowsMultipleSelection = YES;
            break;
        }
        default: {
            self.collectionView.allowsSelection = NO;
            break;
        }
    }
}


@end
